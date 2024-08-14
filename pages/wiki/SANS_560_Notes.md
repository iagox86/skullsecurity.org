---
title: 'Wiki: SANS 560 Notes'
author: ron
layout: wiki
permalink: "/wiki/SANS_560_Notes"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/SANS_560_Notes"
---

**560.1 Sans 560: Network Penetration and Ethical Hacking**

## Definitions

-   Threat: Agent That can Cause harm
-   Vulnerability: A flaw that can be exploited
-   Risk: Overlap of Vulnerability and threat
-   Exploit: Code/Technique used by a threat on a vulnerability
-   Active attack: manipulates target
-   Passive Attack: Does not manipulate target
-   Ethical Hacking: Using attack techniques to find flaws with permission, to improve security ( aka white hat hacker )
-   Penetration testing: An attempt to gain entry to a network
-   Security Assessments/Vulnerability Assessment: Finding vulnerabilities
-   Security Audit: Comparing findings against a set of standards
-   Phases of an attack
    -   Recon
    -   Scanning
    -   Exploitation
-   Pentesting limitations:
    -   Scope
    -   Time
    -   Methods
-   Pentester limitations:
    -   scope
    -   time
    -   methods

## Public/Free methodologies {#publicfree_methodologies}

Open Source Security Testing Methodology Manual [1](http://www.isecom.org/osstmm/)

-   Focus on Transparency, business value
-   Broad descriptions of categories
-   Numerous templates

NIST [2](http://www.nist.gov/)

-   Processes
-   Roles
-   Tools
-   High-level

OWASP [3](http://www.owasp.org/index.php/Main_Page)

-   Web app testing
-   compares impact: likelihood

Penetration Testing Framework [4](http://www.vulnerabilityassessment.co.uk/Penetration%20Test.html)

-   Network penetration tests
-   Specific tools, commands
-   Step-by-step
-   Recon
-   Social Engineering
-   Scanning/probing
-   enumeration

## Overall Methodology {#overall_methodology}

Preparation

-   Sign a NDA
-   Discuss nature of the test
    -   Identify threats/Concerns
    -   Agree on rules of engagement
    -   Determine scope of test
-   Sign off on permission, notice of danger
    -   Vital to get before starting
    -   \"Get out of jail free\" card
-   Assign team

Testing

-   Conduct the test

Conclusion

-   Perform detailed analysis
-   Retest
-   Reporting
-   Presentation

## Limitation of liability/insurance {#limitation_of_liabilityinsurance}

-   Should be drawn up by a lawyer
-   Generally limited to a value of project

## Rules of Engagement {#rules_of_engagement}

-   Emergency contact info ( 24/7 )
-   Daily debriefings
-   Dates and times of day
-   Announced/unannounced
-   Shunning ( IDS/IPS )
-   Black-box vs Crystal-box testing
-   Viewing data on compromised systems
-   Observing tests
-   **Document agreements and both sign off**

## Scope

What are biggest concerns?

-   Disclosure of sensitive info
-   Interruption in production processing
-   Embarrassment ( defacement )
-   Compromising for deeper penetration

Avoid scope creep What to test

-   Domain names
-   Address ranges
-   hosts
-   applications

Third party System

-   ISP\'s
-   DNS
-   Hosting
-   Get permission

Test vs. production How to test

-   ping port scan
-   vulnerability scan
-   penetration
-   client-side
-   application
-   physical pen
-   social engineering
-   Internal vs external
-   On-site, granted access
-   On-site, sneak in
-   VPN access
-   Testing client-side
-   Browsers
-   Phishing
-   E-mail exploits

Social Engineering

-   Controversial
-   Ensure explicit permission
-   Define explicit goal
-   Establish pretexts, scripts in advance
-   Use a friendly people person ( female is better)

Denial of Service

-   Check version numbers or try to crush? **Be explicit!**

\"Dangerous\" exploits

-   should they be included?
-   Any test can potentially crash a host

## Reporting

Always Create a report

-   Even for inhouse tests
