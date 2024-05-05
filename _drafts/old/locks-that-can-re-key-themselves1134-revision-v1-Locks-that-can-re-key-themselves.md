---
id: 1643
title: 'Locks that can re-key themselves?'
date: '2013-10-14T12:56:42-05:00'
author: 'Ron Bowes'
layout: revision
guid: 'http://blog.skullsecurity.org/2013/1134-revision-v1'
permalink: '/?p=1643'
---

Hey everybody,

As I'm sure you all know, I normally post about IT security here. But, once in awhile, I like to take a look at [physical security](http://www.skullsecurity.org/blog/2009/two-locks-one-bike), even if it's just in jest.

Well, this time it isn't in jest. I was at Rona last week buying a lead/asbestos/mold-rated respirator (don't ask!), when I took a walk down the lock aisle. I'm tired of all my practice locks and was thinking of picking up something interesting. Then I saw it: a lock that advertised that it could re-key itself to any key. Woah! I had to play with it.

Now, maybe I'm an idiot (in fact, my best friends would swear it). But I hadn't ever heard of a lock that can do that before! So I did the obvious thing: I bought it, took it apart, figured out how it worked, then took pictures of everything.

## How it's used

So, in normal use, this is what you do.

When you take it out of the package, it looks like a normal lock with an extra little hole in the side:  
[![](/blogdata/rekey_1_small.jpg)](/blogdata/rekey_1.jpg)

You stick in the proper key, turn it a 1/4 turn (so the key is horizontal), as shown here:  
[![](/blogdata/rekey_2_small.jpg)](/blogdata/rekey_2.jpg)

Then, in the little hole, you use the special "re-key" tool that it comes with:  
[![](/blogdata/rekey_3_small.jpg)](/blogdata/rekey_3.jpg)

Once the tool's been inserted, you can pull out the key:  
[![](/blogdata/rekey_4_small.jpg)](/blogdata/rekey_4.jpg)

At this point, the lock is in "re-key mode". I'll talk about how it works later, but you can now insert any key that matches the warding:  
[![](/blogdata/rekey_5_small.jpg)](/blogdata/rekey_5.jpg)

Turn it back to the original position:  
[![](/blogdata/rekey_6_small.jpg)](/blogdata/rekey_6.jpg)

And remove it:  
[![](/blogdata/rekey_7_small.jpg)](/blogdata/rekey_7.jpg)

Congratulations! The lock is now keyed to the new key instead of the old key. How the hell did that happen!?

## Vocabulary

Just some quick definitions to help you follow (I'm stealing phrases from normal locks that shouldn't really apply to this one, but it's convenient):

**Key pins** are the pins that touch the key

**Driver pins** are the pins (in this case, with a saw-tooth) that don't touch the key

**Key cylinder** is the half of the cylinder that you insert the key into (and that houses the key pins)

**Loose cylinder** is the other half of the cylinder that I couldn't think of a good name for

**The bar** is an oddly shaped metal bar that fits into the loose cylinder.

## How it works

Naturally, the next thing I did was take the lock apart. As soon as I removed a couple bits that held it together, the whole cylinder slid out, fell on my desk, and all the little pieces went everywhere. An hour later, I got it re-assembled and working again, and this is what it looked like:  
[![](/blogdata/rekey_8_small.jpg)](/blogdata/rekey_8.jpg)  
Don't forget, you can click on the pictures for a bigger version!

Anyway, there are actually two half-cylinders (that I'm calling the key cylinder and the loose cylinder) held together by simply being in the lock, plus the bar across the back of one, 5 loose driver pins on the inside, and 5 key pins that can't easily be removed.

[![](/blogdata/rekey_9_small.jpg)](/blogdata/rekey_9.jpg)

In that picture, there are two important details that I called out. First, the slot in the bottom of the loose cylinder fits into the '- - - - -' on the key cylinder. Second, the jagged part of the driver pins fits on a little hook on the key pins. Those two facts are important both for the re-key and the locking.

Here's a closeup of what I'm calling the driver pins:  
[![](/blogdata/rekey_10_small.jpg)](/blogdata/rekey_10.jpg)

Note that they have two grooves, one on the front and one on the back (for the purposes of the narrative, the front is on the right). The groove on the front, as we saw earlier, fits into the '- - - - -' pattern on the key cylinder. The groove on the back fits into the bar, shown above, that goes onto the back of the loose cylinder.

## Re-keying

So let's look at how the re-key mechanism work!

First, recall that the driver pins have a groove that fits into a '- - - - -' on the lock:  
[![](/blogdata/rekey_11_small.jpg)](/blogdata/rekey_11.jpg)

In normal use, these pins freely move up and down beside the '-' marks. They're pulled up and down by the little hooks on the key pins. When the proper key is inserted, the grooves on all five pins will line up with (but DON'T hook onto) the five '-' marks:  
[![](/blogdata/rekey_16_small.jpg)](/blogdata/rekey_16.jpg)

Then the re-key tool is inserted:  
[![](/blogdata/rekey_13_small.jpg)](/blogdata/rekey_13.jpg)[![](/blogdata/rekey_12_small.jpg)](/blogdata/rekey_12.jpg)

This slides the groove on the driver pins onto the '-' marks. Not that this **cannot happen** if the key is the wrong one. That's an important part of the security. Here's what it looks like if the loose cylinder is removed (I only did two pins because setting this up is like balancing a coin on its side):  
[![](/blogdata/rekey_17_small.jpg)](/blogdata/rekey_17.jpg)

When you remove the key, the driver pins will rest in the "good" position - that is, in the position that lets the cylinder rotate and that lets it be re-keyed - thanks to the grooves they're now sitting on. The key pins, which are no longer hooked on the driver pins, will return to their original positions.

When you insert a new key, the key pins will return to a new position while the driver pins are still in the "good" position (that lets you re-key/unlock).

When you turn the key back, the driver pins will come off the '-' marks and wind up back on the key pins' grooves. But the location of the driver pins has changed - the key that lines up all the grooves is now the new key, not the old one!

This design is, in my opinion, brilliant! It's pretty straight forward, now, to see how it locks.

## Locking

Now that we know how the pins work, as I said, the locking is actually pretty straight forward. Remember that bar along the back of the removable cylinder we saw earlier?  
[![](/blogdata/rekey_10_small.jpg)](/blogdata/rekey_10.jpg)

Well, that's the key (ha!) to this whole thing.

Basically, when no key or the wrong key is inserted, it stays locked in position jutting out from the cylinder:  
[![](/blogdata/rekey_14_small.jpg)](/blogdata/rekey_14.jpg)

When the proper key is inserted, it can be pushed back in:  
[![](/blogdata/rekey_15_small.jpg)](/blogdata/rekey_15.jpg)

This is because of the groove on the backs of the pins. The bar rests on the pins but can only be pushed in when the five grooves of the five pins are in the proper place.

And that's it!

## Security

Based on what I've seen, it appears that these locks can likely be picked in two different ways. The standard way, using a tension wrench, has several issues:

- It's difficult to get the pick into the keyway due to the warding
- Every pin is grooved along the back so it sets improperly all over the place
- Because the key pins pull up the driver pins, you don't get the same feeling when the pins are setting

I had another idea for picking, though, that I don't have the right tool to accomplish. The standard way is to turn the cylinder and rely on it causing the bar along the back to put pressure on the pins, but the pins have a sawtooth along the back to set falsely. That's difficult. However, if we put tension on the re-key hole, then we're pushing the pins towards the back of the lock onto the '- - - - -' lines. There's no security on the sides of the pin, so, in theory, it should pick a whole lot easier. And, once you've picked it, you'll be able to re-key and never pick it again. BAM!

Unfortunately, you need a thin tool that can maintain a constant pressure, and I can't think of anything like that. Any ideas?

Hope you enjoyed this somewhat non-standard posting!