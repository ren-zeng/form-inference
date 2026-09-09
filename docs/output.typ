#import "@preview/zebraw:0.6.3": *
#import "@preview/prequery:0.2.0"
#show: zebraw-init


== Musical examples
The musical examples, including scores and audios, links to the official #link("https://acf.research.mcgill.ca/")[#text(fill: blue)[Analyzing Classical Form]] website.

Among the #link("https://acf.research.mcgill.ca/supp_list.php")complete list of example we look at how the form inference model perform on only a few of them.

== Model output

=== Identifying presentation


#let caplinWebsite = "https://acf.research.mcgill.ca/"
#let displayCaplin(prefix, num) = [
  ==== #text(prefix + " " + num)
  #link(caplinWebsite + prefix + num + ".php")[#prequery.image(
    caplinWebsite + prefix + num + ".png",
    "assets/" + prefix + num + ".png",
    width: 50%,
  )]
  #link(caplinWebsite + prefix + num + ".mp3")[
    🔊 *Click to Play*
  ]
]

#let example(num) = displayCaplin("example", num)
#let supp(num) = displayCaplin("supp", num)


#example("2-11")


We distinguish between bindings for idea and bindings for formal unit binding. For the presentation, it is the idea that is repeats, while for the period the repeating thing is the formal unit (ABAC)

#raw(read("ex2_11.txt"), block: true)

This example illustrates the basics of how variable binding leads to smaller size. By default, we assign a high cost of raw repetition markers from the input (as they are placeholders for the surface motivic ideas). On the other hand, calling a binding variable just cost 1.

#pagebreak()


#example("2-12")

This time we make the input a little bit harder in that the basic idea is not an atomic marker, but the concatenation of two. And the model need to identify the repetition of "a"+"b" as the basic idea, and correctly build up the phrase parameter for the concatenated phrases.

#raw(read("ex2_12.txt"), block: true)
#pagebreak()

=== Identifying compound themes


#example("6-1")

#raw(read("ex6_1.txt"), block: true)
#pagebreak()


#example("6-2")

#raw(read("ex6_2.txt"), block: true)
#pagebreak()


#example("6-5")

#raw(read("ex6_5.txt"), block: true)
#pagebreak()

=== Others

#supp("6-1")

#example("5-11")