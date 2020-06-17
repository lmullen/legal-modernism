# adj2edge

A network [adjacency list](https://en.wikipedia.org/wiki/Adjacency_list) stores a network like so:

```
1,2,3
2,3
3
4,2
```

In that format, `1` is adjacent to `2` and `3`, and so on.

But for our purposes it is more convenient to represent the network as an [edge list](https://en.wikipedia.org/wiki/Edge_list), like so:

```
1,2
1,3
2,3
4,2
```

This script can be used to convert the [citations graph](https://case.law/download/citation_graph/) from the Caselaw Access Project from their adjacency list to an edge list.

Run it like so:

```
go run adj2edge.go citations.csv citations-edge.csv
```
