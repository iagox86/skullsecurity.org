---
title: 'Wiki: PDDB'
author: ron
layout: wiki
permalink: "/wiki/PDDB"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/PDDB"
---

# Public DNS Database {#public_dns_database}

The core idea of this project is the collection, aggregation, and dissemination of the data stored in the Internet\'s DNS hierarchy.

## Dissemination

Our goal is for the data we collect to be useful in the widest variety of ways. To this end, there will be three ways to access the data in the beginning of the project:

1.  A user may access our website, and perform queries there. Users may perform query by specific IP addresses, ranges of IP addresses, and with wildcards against the text fields with which the IP addresses are connected. No login will be required to access this service.
2.  Programs may access query our web API, enabling them to use the data in new and exciting ways.
3.  On a monthly basis, a highly-compressed torrent of the current *snapshot* view of the DNS hierarchy will be published. This torrent will not include historical data, to prevent it from growing too quickly. We may also provide a full, historical dump of our data at wider intervals. We expect the torrents will be useful to both researchers, and those who\'d prefer to keep their queries as private as possible.

Additional methods of accessing the data have been proposed, but are of a lower priority. Such methods include:

1.  Custom reports that are available as Atom/RSS feeds, that let users keep up-to-date.
2.  Custom reports that are sent out periodically through email, that let users keep up-to-date.

## Collection

## Verification

We can never be absolutely sure of the veracity of the records in our database. The problem stems from many sources:

-   A distributed effort that anyone can assist in is vulnerable to malicious users, any number of whom can submit erroneous data in hopes of either skewing our results or compromising our system.
-   We cannot trust that all of the DNS responses we receive from the servers will be accurate.
    -   Intermediate servers may have a cached record that is stale.
    -   Servers may have fallen victim to [cache poisoning](http://en.wikipedia.org/wiki/DNS_cache_poisoning).
    -   Servers may give different responses based on where a query comes from (e.g. [CDNs](http://en.wikipedia.org/wiki/Content_delivery_network), [anycast](http://en.wikipedia.org/wiki/Anycast)).
    -   Some ISPs [hijack](http://en.wikipedia.org/wiki/DNS_hijacking) NXDOMAIN responses.

## Aggregation
