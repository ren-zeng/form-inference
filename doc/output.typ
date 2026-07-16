#import "@preview/zebraw:0.6.3": *
#show: zebraw

== model output

=== Identifying presentation

==== ex 2.11
#image("/assets/2_11.png")


We distinguish between bindings for idea and bindings for formal unit binding. For the presentation, it is the idea that is repeats, while for the period the repeating thing is the formal unit (ABAC) 

#raw(read("ex2_11.txt"),block: true)

This example illustrates the basics of how variable binding leads to smaller size. By default, we assign a high cost of raw repetition markers from the input (as they are placeholders for the surface motivic ideas). On the other hand, calling a binding variable just cost 1. 

#pagebreak() 

==== ex 2.12
#image("/assets/2_12.png")
This time we make the input a little bit harder in that the basic idea is not an atomic marker, but the concatenation of two. And the model need to identify the repetition of "a"+"b" as the basic idea, and correctly build up the phrase parameter for the concatenated phrases.

#raw(read("ex2_12.txt"),block: true)
#pagebreak() 

=== Identifying compound themes 

==== ex 6.1
#image("/assets/6_1.png")
#raw(read("ex6_1.txt"),block: true)
#pagebreak() 

==== ex 6.2
#image("/assets/6_2.png")
#raw(read("ex6_2.txt"),block: true)
#pagebreak() 

==== ex 6.5
#image("/assets/6_5.png")
#raw(read("ex6_5.txt"),block: true)
#pagebreak() 