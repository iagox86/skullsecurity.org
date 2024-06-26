---
id: 2488
title: 'BSidesSF CTF: Choose your own keyventure: rsa-debugger challenge!'
date: '2020-03-02T13:39:49-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'https://blog.skullsecurity.org/2020/2467-revision-v1'
permalink: '/?p=2488'
---

*Thanks to **[symmetric](https://twitter.com/bmenrigh)** (aka Brandon Enright) for this wonderful guest post! I tried to proofread it, but holy math Batman!! --Ron / @iagox86*

Hey all, this is symmetric here! I was thrilled to be once again involved in running the BSidesSF CTF with such creative teammates and skilled CTF players.

My favorite challenge this year was ***rsa-debugger*** which, despite getting 12 solves, was actually quite hard. In this post I’d like to tell you a bit about the genesis of the challenge and how to solve it.

## Curveball, but for RSA

As I was really ramping up challenge making this year Microsoft had the great timing to release [CVE-2020-0601](https://portal.msrc.microsoft.com/en-US/security-guidance/advisory/CVE-2020-0601). As something of a "crypto nerd" I was pretty interested in the details. Fortunately Thomas Ptacek ([@tqbf](https://twitter.com/tqbf)) wrote up a great [first-take on the vulnerability on Hacker News](https://news.ycombinator.com/item?id=22048619) which turned out to be essentially spot-on. tbqf also linked to [Cryptopals Exercise 61](https://toadstyle.org/cryptopals/61.txt) which gets even further into the math behind the Curveball attack.

But the relevant part of that exercise was the final comment about RSA:

> Since RSA signing and decryption are equivalent operations, you can use this same technique for other surprising results. Try generating a random (or chosen) ciphertext and creating a key to decrypt it to a plaintext of your choice!

When I read that, I *knew* I had to make a challenge that would have users do just that!

## Enter the rsa-debugger

After playing around in my calculator of choice [GP/PARI](https://pari.math.u-bordeaux.fr/) for a bit more than a week I felt like I understood the gist of the math needed to start building a challenge. I spent a few days thinking about various story scenarios to justify the ability to generate your own key and eventually came to the idea of a satellite debugging interface.

Here is what the challenge looks like:

```
$ nc rsa-debugger-2ad07dbc.challenges.bsidessf.net 1717

              ______               K         /$$$$$$$
           ,'"       "-._         C         | $$__  $$
         ,'              "-._ _  A          | $$  \ $$
         ;              __,-'/  H           | $$$$$$$/
        ;|           ,-' _,'"'._,'          | $$__  $$
        |:            _,'      |\ '.        | $$  \ $$
        : \       _,-'         | \  '.      | $$  | $$
         \ \   ,-'             |  \   \     |__/  |__/ emote
          \ '.         .-.     |       \
           \  \         "      |        :               /$$$$$$
            '. '.              |        |              /$$__  $$
              '. "-._          |        ;             | $$  \__/
              / |'._ '-._      /       /              |  $$$$$$
             /  | \ '._   "-.___    _,'                \____  $$
            /   |  \_.-"-.___   """"                   /$$  \ $$
            \   :            /"""                     |  $$$$$$/
             '._\_       __.'_                         \______/  atellite
        __,--''_ ' "--'''' \_  '-._
  __,--'     .' /_  |   __. '-.    '-._                           /$$$$$$
 /            '.  '-.-''  __,-'     _,-'                         /$$__  $$
  '.            '.   _,-'"      _,-'                            | $$  \ $$
    '.            ''"       _,-'                                | $$$$$$$$
      '.                _,-'                                    | $$__  $$
        '.          _,-'                                        | $$  | $$
          '.   __,'"                                            | $$  | $$
            ''"                                                 |__/  |__/ ttack

Welcome to the Remote Satellite Attack Debugger!

Try "help" for a list of commands
```

If you run help you’ll see a list of the commands:

```
RSA debugger> help
Remote Satellite Attack Debugger help:

Commands:
    help            # Prints this help
    background      # Explain how the attack works
    holdmsg         # Holds a suitable message from being transmitted
    printmsg        # Prints the currently held message
    printtarget     # Prints the target plaintext for currently held msg
    setp <int>      # Set p to the value specified
       e.g. setp 127
    setq <int>      # Set q to the value specified (p must be set)
       e.g. setq 131
    sete <int>      # Set e to the value specified (p & q must be set)
       e.g. sete 17
    printkey        # Prints the current attack key
    resetkey        # Clears all the set key parameters
    testdecrypt     # Locally decrypts held message with current key
    attack          # Send the key and held message to the satellite
    exit            # Exit the hacking interface
```

Importantly the ***background*** command explains to the scenario to the player and spells out the details of what to do:

```
RSA debugger> background
Remote Satellite Attack Debugger background:

Our agents were able to obtain a working prototype of one of the SATNET
satellites and through extensive reverse engineering uncovered a
debugging interface that has not been disabled. We believe we've
uncovered a vulnerability that will let us take control of a satellite.
If we sent our own messages to the satellite, we'd get caught in the
message audit. Instead, we've found a way to intercept and delay messages
in transmission. By uploading a new key via the debugging interface we
should be able to manipulate how the satellite interprets the message after
the message is decrypted.

The attack:
Using the command <strong><em>holdmsg</em></strong> we will begin searching the outbound messages
for a suitable message ciphertext. When a message is found, we can derive
the plaintext that we need the message to decrypt to. You can see the held
message with <strong><em>printmsg</em></strong> and the desired plaintext with <strong><em>printtarget</em></strong>.

The satellite will accept a new private key with only a few basic checks:
1) p and q must be primes
2) p and q must be co-prime
3) e must be co-prime to the Euler totient of n

Note that we only send the satellite p, q, and e and it derives n and d.

When the right key has been found, use <strong><em>attack</em></strong> to upload the new key
and release the held message. The satellite will decrypt the message
with our provided key. If the resulting plaintext contains the target
debugging commands we should gain control of the satellite.
```

## A primer on "textbook RSA"

Since this challenge is clearly about RSA it’s worth a reminder about how RSA works.

Recall that RSA is a clever mathy system where that encrypts and decrypts numbers (not bits and bytes). To handle "messages" they first need to be converted into numbers.

If you have a message, ***M***, then RSA can encrypt ***M*** into ciphertext ***C*** using some other numbers ***E*** and ***N*** like so:

```
C = M^E mod N
```

Decryption is the same operation but instead using a number ***D*** instead of ***E***:

```
M = C^D mod N
```

The magic that makes all this work is in how ***N***, ***E***, and ***D*** are initially generated. Typically ***N*** is the product of two large primes, ***P*** and ***Q***:

```
N = P * Q
```

The reason ***N*** is made in this way is that when ***P*** and ***Q*** are large, ***N*** is hard to factor. This matters because ***E*** and ***D*** have a special relationship that depends on knowing ***P*** and ***Q***:

```
E * D mod ((P - 1) * (Q - 1)) = 1
```

In other words, ***E*** and ***D*** are "multiplicative inverses" of each other ***mod (P - 1) \* (Q - 1)***. If you know ***P*** and ***Q*** it’s pretty easy to find a ***E*** and ***D*** with this property but without ***P*** and ***Q*** you can’t.

(In case you’ve ever wondered why the inverse needs to be mod ***(P - 1) \* (Q - 1)*** It’s because of the [multiplicative order](https://en.wikipedia.org/wiki/Multiplicative_order) ***mod N*** is depends on [Euler’s Totient](https://en.wikipedia.org/wiki/Euler%27s_totient_function) of ***N*** which requires knowing the prime factorization of ***N***.)

## Back to the challenge

With a bit of RSA under our belt, what is this challenge asking us to do? Per the ***background*** command, the challenge is going to choose an ***M*** and a ***C*** for us and then we’re going to have to have to be very clever to find a ***E***, ***D***, and ***N*** such that

```
C^D mod N = M
```

In short, we’re told both the message ***M*** and the ciphertext ***C*** and we have to create a key that can transform one into the other!

With ***holdmsg***, ***printmsg***, and ***printtarget*** we can see ***M*** and ***C***:

```
RSA debugger> holdmsg
Holding message.....found a message to hold!
Target plaintext derived.

RSA debugger> printmsg
Held Message: 30029082298423626458918317331797730712824458279653960314522818831988750307318019279067726121277119878053175539620927367012778946811416906341414123860864244749552521552311233414710306128250462784249834553759849615395773977911763564663657767431530992587212144895290159185785995293643942721086593148607174895850948443533014356220154193758581121774858597565799411158140225719721204831369243444675595874337654786964512086698884078659044535454015012519885849752458458138292456648904712847039358841233152424391826191616205077655575599508690865770150633936794333505044169469961152517435570928708737545883090196719522419964479

RSA debugger> printtarget
Target plaintext for held message: 52218557622655182058721298410128724497736237107858961398752582948746717509543923532995392133766377362569697102943053
```

From this point I’m going to start working in a calculator ***gp***:

```
$ gp -q

GP/PARI> C = 30029082298423626458918317331797730712824458279653960314522818831988750307318019279067726121277119878053175539620927367012778946811416906341414123860864244749552521552311233414710306128250462784249834553759849615395773977911763564663657767431530992587212144895290159185785995293643942721086593148607174895850948443533014356220154193758581121774858597565799411158140225719721204831369243444675595874337654786964512086698884078659044535454015012519885849752458458138292456648904712847039358841233152424391826191616205077655575599508690865770150633936794333505044169469961152517435570928708737545883090196719522419964479;

GP/PARI> M = 52218557622655182058721298410128724497736237107858961398752582948746717509543923532995392133766377362569697102943053;
```

First off, how big do we even need ***N*** to be? ***N*** has to be at least as big as the ***C*** and ***M*** and since ***C*** is the bigger of the two we’ll check how many bits we need to use:

```
GP/PARI> log(C) / log(2)

2047.8940668368075220590133314785270257
```

As you can see, ***N*** needs to be at least 2048 bits.

But before we worry too much about ***N*** notice that without the ***mod N*** bit of RSA this problem would be trivial to solve with logarithms:

```
C^D = M 

<em>solve for D</em>

log_C(C^D) = log_C(M)

<em>cancel the the first log</em>

D = log_C(M) 

<em>where log_C(x) is just log-base-C which is log(x)/log(C)</em>
```

To put a set of more concrete numbers to this, if ***C*** were ***125*** and ***M*** were ***5*** then the exponent would have to be ***3***:

```
GP/PARI> log(125)/log(5)

3.0000000000000000000000000000000000000
```

But we can’t just ignore the ***mod N*** bit and that makes the problem a LOT harder. Computing the logarithm ***mod N*** is called the [discrete logarithm](https://en.wikipedia.org/wiki/Discrete_logarithm).

Wikipedia tells us that:

> Discrete logarithms are quickly computable in a few special cases. However, no efficient method is known for computing them in general. Several important algorithms in[ public-key cryptography](https://en.wikipedia.org/wiki/Public-key_cryptography) base their security on the assumption that the discrete logarithm problem over carefully chosen groups has no efficient solution.

What we need to do is carefully choose a group (choose ***N***) to fall into one of these "few special cases" so that we can solve the discrete logarithm efficiently.

One such algorithm for solving discrete logs is [Pohlig–Hellman](https://en.wikipedia.org/wiki/Pohlig%E2%80%93Hellman_algorithm). If you examine the details the key criteria for the algorithm is that the the order of the group must be [smooth](https://en.wikipedia.org/wiki/Smooth_integer). All that smooth really means is that the order must factor into many small prime numbers and no big prime numbers.

In other words ***720*** is "smooth" because it factors to ***2^4 \* 3^2 \* 5*** and ***2***, ***3***, and ***5*** are all small prime numbers. ***721*** is much less smooth because it factors into ***7 \* 103*** and ***103*** is a much bigger prime number.

The "order of the group" for numbers mod ***N*** is ***(P - 1) \* (Q - 1)*** when ***N = P \* Q*** and ***P*** and ***Q*** are both primes (and not the same prime!).

What this means is that we’re going to need to find a set of primes ***P*** and ***Q*** where both ***P - 1*** and ***Q - 1*** have many small prime factors. One way to do that is to just generate ***P - 1*** and ***Q - 1*** by multiplying a bunch of small primes together and then checking if ***P*** and ***Q*** are prime.

Using GP/PARI we can generate smooth numbers with ***b*** bits and a maximum prime factor of ***l*** with:

```
candidatep(b,l) = {my(p); p = 2; while(log(p)/log(2) < b, p = p * nextprime(random(l))); p + 1;};
```

And then we can just generate those over and over until we get a prime:

```
divisiblep(b,l) = {my(p); p = 1; while(isprime(p) != 1, p = candidatep(b,l)); p;};
```

Fortunately for us, most sophisticated computer algebra systems offer a discrete logarithm function so that we don’t have to fully understand and implement Pohlig–Hellman ourselves. GP/PARI calls its discrete logarithm ***znlog(...)***. If we find a good ***N*** using smooth ***P - 1*** and ***Q - 1*** then the algorithm should work.

One wrinkle in all of this is that I’ve failed to mention is that ***C^x mod N = M*** doesn’t always have a solution. Wikipedia’s article on [primitive roots mod n](https://en.wikipedia.org/wiki/Primitive_root_modulo_n) goes into more detail. One useful detail in the article is that if ***N = 2 \* P*** where ***P*** is smooth then there is guaranteed to be a primitive root. Unfortunately for us the existence of a primitive root isn’t directly useful for us because we can’t control the base ***C***. If we use ***N = 2 \* P*** then there will only be about a 50% chance ***C^x mod N = M*** has a solution. We can just keep trying new ***N*** until we find an ***N*** that does have a solution though.

## Putting all this math together

Since we already have our ***M*** and ***C*** from the challenge we need to find a ***N*** and ***E*** and ***D*** to make ***C^D mod N = M***.

First we’ll just use ***Q = 2*** so that we only have to worry about making a smooth ***P - 1***:

```
GP/PARI> Q = 2
2

GP/PARI> P = divisiblep(2048, 10^6)
161942790351244111036788766268852169472724200463405321444275428165925234129239820471483973695508532755692958440820487979596414996221366363934327341277682431876497539553388643573870274241659075169583323901310718672047320389845442875393244229463443343709199788739536898546865172684811427132263150099893686873362529122381428639845198852716961306096014906299004547972707536919620883342087989353399376044575854781130187775292645676475293013697177776724697108863611165674450215691220591194914537613364659405755997950596757834687785898108059874418881747635460222297069814843757222031884856609061503670464632207753808178151727

GP/PARI> N = P * Q;

GP/PARI> addprimes(P);

GP/PARI> D = znlog(M, Mod(C, N))
29486028974181285156934463927118504924886826745620492866006150449277526899353443427391676780902099431721174906174889541922713739755625254226792766616391723704549333652193757530626244817729805805094138384898551833108717262384512156746051609530306078161009584617885224299458735234680232922269101672710436079025219206604052487550699369372831358790077825054713393927350259099771862457985014999589079972814604583147802999097739995732627401949467352530436218125753152180838846242783254665807550690851484739288927526853329680283164624265698017074986863698402674007475772099513217202416536091630721448875486838869905859113481
```

As you can see, GP/PARI was able to solve the discrete logarithm for us using the ***P*** we generated. We can confirm that the ***D*** that was found will properly decrypt ***C*** into ***M***:

```
GP/PARI> modexp(a, b, n) = { \
    my(d, bin); \
    d = Mod(1, n); \
    bin = binary(b); \
    for (i = 1, length(bin), \
         d = sqr(d); \
         if (bin[i] == 1, \
             d = d*a; \
         ); \
    ); \
    return(d);
}

GP/PARI> lift(modexp(C, D, N))
52218557622655182058721298410128724497736237107858961398752582948746717509543923532995392133766377362569697102943053
```

Now the only remaining trick is that the rsa-debugger challenge doesn’t let us set ***D*** directly. Instead we have to set ***E*** and it will derive ***D***. Fortunately we can easily find ***E*** ourselves:

```
GP/PARI> E = lift(Mod(1 / D, (P - 1) * (Q - 1)))
6535984289377007695869938085512749956440903112435636813121158843470048945527467633957881396532903938497722244114031627721309590138791284357349380902699194418615221586380111129431958544975857456121030749269327188420588764633546747760413300313171087775991577957806352789868210799923751711394998858299526412851051237992880788734452467141174361844450698179323724048185978570827570883100486034321950355304802542352941389537192673255223543121873313878657409558395070334257381507966482551593328088955149714549647143325315983584258379484307487203907867187915099955533462665910194452827634823257531886286209360270500708688033
```

Now that we have all of our constants it’s just a matter of setting them in the challenge:

```
RSA debugger> setp 161942790351244111036788766268852169472724200463405321444275428165925234129239820471483973695508532755692958440820487979596414996221366363934327341277682431876497539553388643573870274241659075169583323901310718672047320389845442875393244229463443343709199788739536898546865172684811427132263150099893686873362529122381428639845198852716961306096014906299004547972707536919620883342087989353399376044575854781130187775292645676475293013697177776724697108863611165674450215691220591194914537613364659405755997950596757834687785898108059874418881747635460222297069814843757222031884856609061503670464632207753808178151727

RSA debugger> setq 2

RSA debugger> sete 6535984289377007695869938085512749956440903112435636813121158843470048945527467633957881396532903938497722244114031627721309590138791284357349380902699194418615221586380111129431958544975857456121030749269327188420588764633546747760413300313171087775991577957806352789868210799923751711394998858299526412851051237992880788734452467141174361844450698179323724048185978570827570883100486034321950355304802542352941389537192673255223543121873313878657409558395070334257381507966482551593328088955149714549647143325315983584258379484307487203907867187915099955533462665910194452827634823257531886286209360270500708688033

RSA debugger> printkey

Current key parameters:

p: 161942790351244111036788766268852169472724200463405321444275428165925234129239820471483973695508532755692958440820487979596414996221366363934327341277682431876497539553388643573870274241659075169583323901310718672047320389845442875393244229463443343709199788739536898546865172684811427132263150099893686873362529122381428639845198852716961306096014906299004547972707536919620883342087989353399376044575854781130187775292645676475293013697177776724697108863611165674450215691220591194914537613364659405755997950596757834687785898108059874418881747635460222297069814843757222031884856609061503670464632207753808178151727

q: 2

derived n: 323885580702488222073577532537704338945448400926810642888550856331850468258479640942967947391017065511385916881640975959192829992442732727868654682555364863752995079106777287147740548483318150339166647802621437344094640779690885750786488458926886687418399577479073797093730345369622854264526300199787373746725058244762857279690397705433922612192029812598009095945415073839241766684175978706798752089151709562260375550585291352950586027394355553449394217727222331348900431382441182389829075226729318811511995901193515669375571796216119748837763495270920444594139629687514444063769713218123007340929264415507616356303454

e: 6535984289377007695869938085512749956440903112435636813121158843470048945527467633957881396532903938497722244114031627721309590138791284357349380902699194418615221586380111129431958544975857456121030749269327188420588764633546747760413300313171087775991577957806352789868210799923751711394998858299526412851051237992880788734452467141174361844450698179323724048185978570827570883100486034321950355304802542352941389537192673255223543121873313878657409558395070334257381507966482551593328088955149714549647143325315983584258379484307487203907867187915099955533462665910194452827634823257531886286209360270500708688033

derived d: 29486028974181285156934463927118504924886826745620492866006150449277526899353443427391676780902099431721174906174889541922713739755625254226792766616391723704549333652193757530626244817729805805094138384898551833108717262384512156746051609530306078161009584617885224299458735234680232922269101672710436079025219206604052487550699369372831358790077825054713393927350259099771862457985014999589079972814604583147802999097739995732627401949467352530436218125753152180838846242783254665807550690851484739288927526853329680283164624265698017074986863698402674007475772099513217202416536091630721448875486838869905859113481
```

Now if we run the ***testdecrypt*** command we’ll see it matches the desired target plaintext:

```
RSA debugger> testdecrypt

Message decrypted to: 52218557622655182058721298410128724497736237107858961398752582948746717509543923532995392133766377362569697102943053
```

And when we run ***attack***:

```
RSA debugger> attack

Satellite response: CTF{curveball_not_just_for_ecc}
```

And that’s it! I hope all the teams that solved the challenge had as much fun and learned as much as I did making the challenge!