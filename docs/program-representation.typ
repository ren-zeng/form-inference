#import "@preview/zebraw:0.6.3": *
#show: zebraw
= Program representation of musical form


We aim towards a program representation of form structure, by borrowing and formalizing ideas from caplin's theory of classical form. Inferring form structure becomes searching for the smallest program under this universe. 


Musical form is a recursive structure built from finite means of temporally concatenating musical content. Caplin's theory of classical form distills the ways of concatenation into a small collection, including but not limited to, sentence and period. 




== Alternative representation of musical form

=== [music theory] Why not just use contraints?
Usually one learns the notion of a formal unit based on a list of constraints imposed on its internal segments. For instance, for a sentence "the presentation should expresses a prolongation of local tonic", "the presentation should consists of two identical motivic ideas", "the continuation should end with a cadence", "the continuation usually features a fragmentation of the basic idea", etc. 

Why should't the notion of a formal unit (e.g. sentence) be based on a list of constraints imposed on its internal segments?

A constraint-only system deduce predicate on time spans, such as "measure i to j can fits the notion of antecedent". 

The main limitation with contraint-only encoding is that it has no impact on description length, which is a crucial disambiguation mechanism. 



=== [compression] Why not just use concatenation and standard list manipulation function?


=== [expressivity] Why not just use lambda calculus?

