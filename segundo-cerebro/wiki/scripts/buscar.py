#!/usr/bin/env python3
"""Búsqueda BM25 sobre todo el segundo cerebro — para cuando el índice (wiki/index.md)
no basta para encontrar una página.

Uso:
    python3 wiki/scripts/buscar.py "consulta en lenguaje natural" [N]

Sin dependencias externas — solo librería estándar. Indexa en memoria en cada corrida.
"""

import math
import re
import sys
import unicodedata
from pathlib import Path

VAULT = Path(__file__).resolve().parents[2]
EXCLUDE_DIRS = {".git", ".obsidian", ".claude", ".codex", "node_modules"}
K1 = 1.5
B = 0.75


def fold(text: str) -> str:
    text = unicodedata.normalize("NFKD", text)
    return "".join(c for c in text if not unicodedata.combining(c)).lower()


def tokenize(text: str) -> list[str]:
    return re.findall(r"[a-z0-9]+", fold(text))


def iter_notes():
    for path in VAULT.rglob("*.md"):
        if any(part in EXCLUDE_DIRS for part in path.parts):
            continue
        yield path


def load_corpus():
    docs = []
    for path in iter_notes():
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        docs.append((path, text))
    return docs


def build_index(docs):
    tokenized = [tokenize(text) for _, text in docs]
    doc_freq = {}
    for tokens in tokenized:
        for term in set(tokens):
            doc_freq[term] = doc_freq.get(term, 0) + 1
    avgdl = sum(len(t) for t in tokenized) / max(len(tokenized), 1)
    return tokenized, doc_freq, avgdl


def bm25_score(query_terms, tokens, doc_freq, n_docs, avgdl):
    freq = {}
    for t in tokens:
        freq[t] = freq.get(t, 0) + 1
    dl = len(tokens)
    score = 0.0
    for term in query_terms:
        n_t = doc_freq.get(term, 0)
        if n_t == 0:
            continue
        idf = math.log((n_docs - n_t + 0.5) / (n_t + 0.5) + 1)
        f = freq.get(term, 0)
        if f == 0:
            continue
        denom = f + K1 * (1 - B + B * dl / avgdl)
        score += idf * (f * (K1 + 1)) / denom
    return score


def snippet(text: str, query_terms, width=160) -> str:
    lines = text.splitlines()
    for line in lines:
        if any(term in fold(line) for term in query_terms):
            line = line.strip()
            return line[:width] + ("…" if len(line) > width else "")
    stripped = text.strip().replace("\n", " ")
    return stripped[:width] + ("…" if len(stripped) > width else "")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    query = sys.argv[1]
    top_n = int(sys.argv[2]) if len(sys.argv) > 2 else 5

    docs = load_corpus()
    if not docs:
        print("No se encontraron notas .md en el vault.")
        sys.exit(1)

    tokenized, doc_freq, avgdl = build_index(docs)
    query_terms = tokenize(query)
    if not query_terms:
        print("Consulta vacía tras tokenizar.")
        sys.exit(1)

    results = []
    for (path, text), tokens in zip(docs, tokenized):
        score = bm25_score(query_terms, tokens, doc_freq, len(docs), avgdl)
        if score > 0:
            results.append((score, path, text))

    results.sort(key=lambda r: r[0], reverse=True)

    if not results:
        print(f"Sin resultados para: {query}")
        sys.exit(0)

    for score, path, text in results[:top_n]:
        rel = path.relative_to(VAULT)
        print(f"{score:.2f}\t{rel}\t{snippet(text, query_terms)}")


if __name__ == "__main__":
    main()
