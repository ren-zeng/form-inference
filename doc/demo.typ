#import "@preview/zebraw:0.6.3": *
#show: zebraw
== Form inference 


== Iteration 1

```hs
data CadenceStrength = Weak | Strong | None

data Harmony = I | II | III | IV | V | VI | VII

data Idea
  = Label String
  | Concat Idea Idea
  | Twice Idea

data PhraseParam = Param [Harmony] CadenceStrength

data FormalUnit
  = Leaf Idea PhraseParam
  | Sentence Idea Idea PhraseParam PhraseParam
  | Period Idea Idea Idea PhraseParam PhraseParam
  | Presentation Idea PhraseParam PhraseParam
  | Concatenate FormalUnit FormalUnit
```

=== example

```
ex1 = Period
        "a"+"b" 
        "c"+"d"
        "c"+"e"
        ⟦I-V-I-V-I-V-IV-V-I-VI-VII-I-V Weak⟧ 
        ⟦I-I-V-V-I Strong⟧ 

      -- which desugars to
      Period 
        (Concat (Label "a") (Label "b")) 
        (Concat (Label "c") (Label "d")) 
        (Concat (Label "c") (Label "e")) 
        (Param [I,V,I,V,I,V,IV,V,I,VI,VII,I,V] Weak) 
        (Param [I,I,V,V,I] Strong)
      
      -- and have size 31 (number of constructors)
```



=== notation

`"a"+"b"` $->$ `Concat (Label "a") (Label "b")`

`⟦I-I-V-V-I Strong⟧` $->$ `Param [I,I,V,V,I] Strong`


#image("/assets/image.png")

```
Input surface:
  {a ⟦I-V None⟧} + {b ⟦I-V-I-V Weak⟧} + {c ⟦IV-V-I None⟧} + {d ⟦VI-VII-I-V Weak⟧} + {a ⟦I-V None⟧} + {b ⟦I-V-I-V Weak⟧} + {c ⟦V None⟧} + {e ⟦I Strong⟧}

Output analysis:
  [ Period
    "a"+"b"
    "c"+"d"
    "c"+"e"
    ⟦I-V-I-V-I-V-IV-V-I-VI-VII-I-V Weak⟧
    ⟦I-V-I-V-I-V-V-I Strong⟧
  , Period
    "a"
    "b"+"c"+"d"
    "b"+"c"+"e"
    ⟦I-V-I-V-I-V-IV-V-I-VI-VII-I-V Weak⟧
    ⟦I-V-I-V-I-V-V-I Strong⟧
  , {"a" ⟦I-V None⟧} + {"b" ⟦I-V-I-V Weak⟧} + Period
    "c" "d"+"a"+"b" "e" ⟦IV-V-I-VI-VII-I-V-I-V-I-V-I-V Weak⟧ ⟦V-I Strong⟧
  , {"a" ⟦I-V None⟧} + {"b" ⟦I-V-I-V Weak⟧} + Period
    "c" "d"+"a"+"b" "e" ⟦IV-V-I-VI-VII-I-V-I-V-I-V-I-V Weak⟧ ⟦V-I Strong⟧
  , {"a" ⟦I-V None⟧} + {"b" ⟦I-V-I-V Weak⟧} + {"c" ⟦IV-V-I None⟧} + {"d" ⟦VI-VII-I-V Weak⟧} + {"a" ⟦I-V None⟧} + {"b" ⟦I-V-I-V Weak⟧} + {"c" ⟦V None⟧} + {"e" ⟦I Strong⟧} ]
```

good: 
- we captured the sharing of information and can thus use MDL to disambiguate among multiple parses
bad: 
- we lose the information about harmony segmentation to the idea level
- we don't get sentence embeded in period directly in the AST 

next step:
- [keep] we want to factor out formal repeats (compressible)
- [change] we want to be able to recover the original surface (lossless encoding)
- [change] we want the AST to be recursive, sentence and period should take FormalUnit as arguments (recursive)

=== Iteration 2
To achieve all of this in a single model, what we can do is use a variable binding (with scope).

```hs
...

data Idea 
  = Label String
  | Reference IdeaVar 
  | Concat Idea Idea 
  

data FormalUnit 
  = Leaf Idea PhraseParam 
  | RefFormalUnit FormVar
  | Period   IdeaBinding FormalUnitBinding FormalUnit FormalUnit
  | Sentence IdeaBinding FormalUnitBinding FormalUnit FormalUnit
  ...

```

Note that FormalUnit is now a recursive AST

ex 6.1
#image("/assets/image.png")
```
Period 
  < A:= Concatenate {a ⟦I-V None⟧} {b ⟦I-V-I-V Weak⟧} > 
  < >
  Sentence 
    < >
    < > 
    A 
    Concatenate {c ⟦IV-V-I None⟧} {d ⟦VI-VII-I-V Weak⟧}
  Sentence 
    < >
    < > 
    A 
    Concatenate {c ⟦V None⟧} {e ⟦I Strong⟧})
```




ex 2.11
#image("/assets/image-1.png")
```
Presentation 
  < x := "a" >
  {x ⟦I None⟧ }
  {x ⟦IV None⟧}
```


ex 2.22
#image("/assets/image-2.png")
```
Presentation
  < x := "a" >
  {x ⟦I-V-IV-V-V/VI⟧ }
  {x ⟦VI-V/VI-V/IV-IVNone⟧}

```






== second sketch:

instead of encoding a formal unit inference as term rewriting, we treat them as predicate over the time span.

For example 
`IsPeriod 0 8` states that measure 1-8 is a period

instead of using rewrite rules like 
... ~> ... under condition ...

we say 

```
TermWithSpan x i k
x = Antecedent _ 
TermWithSpan y k j
y = Consequent _
NoStronger (Cad x) (Cad y)
--------- 
TermWithSpan (Period x y) i j
```

when we want to query the form structure of a span (i,j)
we just need to 


Now we need to come up with the deduction rules (which can be simpler than term rewriting rules)
At the end, the model 