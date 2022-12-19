---
id: 2511
title: 'BSidesSF CTF 2021 Author writeup: Hangman Battle Royale, where you defeat 1023 AI players!'
date: '2021-03-16T11:32:50-05:00'
author: 'Ron Bowes'
layout: post
guid: 'https://blog.skullsecurity.org/?p=2511'
permalink: /2021/bsidessf-ctf-2021-author-writeup-hangman-battle-royale-where-you-defeat-1023-ai-players
categories:
    - Crypto
    - CTFs
    - Default
    - Random
---

Hi Everybody!

This is going to be a challenge-author writeup for the [Hangman Battle Royale](https://github.com/BSidesSF/ctf-2021-release/tree/main/hangman-battle-royale) challenge from [BSides San Francisco 2021](https://ctftime.org/event/1299).

This is actually a reasonable simple challenge, overall. I got the idea of using a bad mt19937 implementation (the Mersenne Twister PRNG used by Ruby and Python) from [SANS Holiday Hack Challenge 2020](https://holidayhackchallenge.com/2020/) (which is still online if you want to play!), and wanted to build a challenge around it. I had the idea of Battleship originally, but ended up deciding on Hangman for reasons I no longer remember, but that I'm sure made sense at the time.

## The game

When you run the game, it prompts for the number of rounds:

```
$ ruby ./hangman.rb
Welcome to Hangman Battle Royale!

================================
           MAIN MENU
================================

How many rounds do you want to play? (2 - 16)

If you play at least 8 rounds, you win the special prize!
```

When you choose a round count, it picks a bunch of CPU names to build brackets:

```
================================
         ROUND 1!
================================

This game's match-ups are:

Meirina Tresvalles    -vs-  Gelbert Chhangte
Kebede Boehmer        -vs-  Karthic Cassity
Mairtin Piedrahita    -vs-  Winston Pawlowski
Brendaliz Lumbang     -vs-  Josipa Perlow
Unusual Ballenger     -vs-  Carmellia Agregado
Jinnie Khalif         -vs-  Jeegar Madela
Vjeran Saltarelli     -vs-  Rachella Newfield

And finally...

YOU                  -vs-  Patience Saravana!
```

## The vulnerability

The actual code powering the list of players uses Ruby's built-in PRNG, which uses a predictable Mersenne Twister to generate random numbers. I don't love how the name-choosing code was a little bit contrived, but it can leak enough state to predict future random numbers:

```
def get_opponents(count)
  return 0.upto(count-1).map do ||
    i = rand(0xFFFFFFFF)
    "#{ FIRST_NAMES[i & 0xFFFF] } #{ LAST_NAMES[i >> 16] }"
  end
end
```

Each pair of names is a single 32-bit integer from the Mersenne Twister PRNG. It turns out, if you can leak [624 32-bit outputs, you can recover the full state](https://github.com/kmyk/mersenne-twister-predictor)! That means if you play at least 10 rounds, you end up with 2<sup>10</sup>-1 names, or 1023 32-bit numbers (because you're the 1024th player).

Once you've gotten the state of the PRNG, you can predict everything else that's going to happen!

## The exploit

[My exploit](https://github.com/BSidesSF/ctf-2021-release/blob/main/hangman-battle-royale/solution/solution.py) is super quick and dirty. It can parse the output from the game and grab the seed using [mt19937predict](https://github.com/kmyk/mersenne-twister-predictor):

```
predictor = MT19937Predictor()
for _ in range(511):
    (a, b) = read_names(i)
    predictor.setrandbits(a, 32)
    predictor.setrandbits(b, 32)
```

(and yes, this is probably the first time I've ever written a Python solution!)

Then does a final validation on your opponent's name to make sure the solution is working:

```
(_, actual) = read_names(i)
first_actual = FIRST_NAMES[actual & 0x0000FFFF]
last_actual = LAST_NAMES[actual >> 16]
final_name_actual = "%s %s" % (first_actual, last_actual)

print("Validating...")
print(" -> Final name (predicted):", final_name_predicted)
print(" -> Final name (actual):   ", final_name_actual)
assert(final_name_predicted == final_name_actual)
```

And prints out the 10 words that will be chosen:

```
for i in range(10, 0, -1):
    word = predictor.getrandbits(32)
    print("Round %d: %s" % (10 - i + 1, WORDS[word & 0xFFFF]))

    # Waste RNG cycles
    for _ in range(1, (2**i) >> 1):
        predictor.getrandbits(64)
```

To use it, I just connect to the game and <tt>tee</tt> the output it into a file:

```
$ ruby hangman.rb | tee /tmp/hangman.txt
Welcome to Hangman Battle Royale!

================================
           MAIN MENU
================================

How many rounds do you want to play? (2 - 16)

If you play at least 8 rounds, you win the special prize!

> 10

================================
         ROUND 1!
================================

This game's match-ups are:

Carleen Murnaghan     -vs-  Willyanto Wahono
Aliecia Knutsen       -vs-  Hareth Christophersen

[... so many names ...]

Sheneen Kottwitz      -vs-  Jitlada Carrick
Janine Sellers        -vs-  Graydon Racuya
Hemali Gettinger      -vs-  Adrianna Chenna

And finally...

YOU                  -vs-  Gifted Adedamola!

GOOD LUCK!!


================================
          PLAYER TURN
================================


Enter a letter to guess a letter, or a word to guess the whole thing:

    _ _ _ _ _ _ _ _ _ _ _ _

Your guess -->
```

Then in another window, I read the output from the tee'd file right into the python solution:

```
$ python ./solution.py < /tmp/hangman.txt
Start a game with TEN (10) rounds, and paste the output (including player map-ups) here!
Validating...
 -> Final name (predicted): Gifted Adedamola
 -> Final name (actual):    Gifted Adedamola
Final names check out!

Here are the words, be sure to enter them without guesses (guesses consume random cycles):
Round 1: hypocoristic
Round 2: utricularia
Round 3: trapanned
Round 4: pseudobranchiate
Round 5: twice
Round 6: misuse
Round 7: lancepesade
Round 8: stroppier
Round 9: musicalizing
Round 10: avowing
```

Then from there, you can just copy and paste all the words! Just don't make a wrong guess, if the CPU guesses that'll consume some RNG state and throw off the predictions:

```
Enter a letter to guess a letter, or a word to guess the whole thing:

    _ _ _ _ _ _ _ _ _ _ _ _

Your guess --> hypocoristic

    h y p o c o r i s t i c

Congratulations, you beat Gifted Adedamola and won this round! Let's see how the others did!

[.....]

Press enter to continue

You win this round!
Wow, that was a MEGA victory!
Flag: CTF{hooray_mt19937}
```

## Conclusion

I was really hoping this would be a fairly easy coding challenge, I was surprised that not a ton of teams solved it!

Hopefully this writeup, and knowing that mt19937predict is a thing will mean that more folks are able to solve this type of challenge in the future!