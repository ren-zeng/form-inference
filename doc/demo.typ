#import "@preview/zebraw:0.6.3": *
#show: zebraw
= Update on form inference model

#outline()

// == Iteration 1

// ```hs
// data CadenceStrength = Weak | Strong | None

// data Harmony = I | II | III | IV | V | VI | VII

// data Idea
//   = Label String
//   | Concat Idea Idea
//   | Twice Idea

// data PhraseParam = Param [Harmony] CadenceStrength

// data FormalUnit
//   = Leaf Idea PhraseParam
//   | Sentence Idea Idea PhraseParam PhraseParam
//   | Period Idea Idea Idea PhraseParam PhraseParam
//   | Presentation Idea PhraseParam PhraseParam
//   | Concatenate FormalUnit FormalUnit
// ```

// === example

// ```
// ex1 = Period
//         "a"+"b" 
//         "c"+"d"
//         "c"+"e"
//         ⟦I-V-I-V-I-V-IV-V-I-VI-VII-I-V Weak⟧ 
//         ⟦I-I-V-V-I Strong⟧ 

//       -- which desugars to
//       Period 
//         (Concat (Label "a") (Label "b")) 
//         (Concat (Label "c") (Label "d")) 
//         (Concat (Label "c") (Label "e")) 
//         (Param [I,V,I,V,I,V,IV,V,I,VI,VII,I,V] Weak) 
//         (Param [I,I,V,V,I] Strong)
      
//       -- and have size 31 (number of constructors)
// ```



// === notation

// `"a"+"b"` $->$ `Concat (Label "a") (Label "b")`

// `⟦I-I-V-V-I Strong⟧` $->$ `Param [I,I,V,V,I] Strong`




// ```
// Input surface:
//   {a ⟦I-V None⟧} + {b ⟦I-V-I-V Weak⟧} + {c ⟦IV-V-I None⟧} + {d ⟦VI-VII-I-V Weak⟧} + {a ⟦I-V None⟧} + {b ⟦I-V-I-V Weak⟧} + {c ⟦V None⟧} + {e ⟦I Strong⟧}

// Output analysis:
//   [ Period
//     "a"+"b"
//     "c"+"d"
//     "c"+"e"
//     ⟦I-V-I-V-I-V-IV-V-I-VI-VII-I-V Weak⟧
//     ⟦I-V-I-V-I-V-V-I Strong⟧
//   , Period
//     "a"
//     "b"+"c"+"d"
//     "b"+"c"+"e"
//     ⟦I-V-I-V-I-V-IV-V-I-VI-VII-I-V Weak⟧
//     ⟦I-V-I-V-I-V-V-I Strong⟧
//   , {"a" ⟦I-V None⟧} + {"b" ⟦I-V-I-V Weak⟧} + Period
//     "c" "d"+"a"+"b" "e" ⟦IV-V-I-VI-VII-I-V-I-V-I-V-I-V Weak⟧ ⟦V-I Strong⟧
//   , {"a" ⟦I-V None⟧} + {"b" ⟦I-V-I-V Weak⟧} + Period
//     "c" "d"+"a"+"b" "e" ⟦IV-V-I-VI-VII-I-V-I-V-I-V-I-V Weak⟧ ⟦V-I Strong⟧
//   , {"a" ⟦I-V None⟧} + {"b" ⟦I-V-I-V Weak⟧} + {"c" ⟦IV-V-I None⟧} + {"d" ⟦VI-VII-I-V Weak⟧} + {"a" ⟦I-V None⟧} + {"b" ⟦I-V-I-V Weak⟧} + {"c" ⟦V None⟧} + {"e" ⟦I Strong⟧} ]
// ```

// good: 
// - we captured the sharing of information and can thus use MDL to disambiguate among multiple parses
// bad: 
// - we lose the information about harmony segmentation to the idea level
// - we don't get sentence embeded in period directly in the AST 

// next step:
// - [keep] we want to factor out formal repeats (compressible)
// - [change] we want to be able to recover the original surface (lossless encoding)
// - [change] we want the AST to be recursive, sentence and period should take FormalUnit as arguments (recursive)

== The context of the project
We break the overarching form inference (model : piece at the note level $->$ FormTree) into 3 parts

- harmonic reduction model : piece at the note level $->$ harmony and cadence label

  - example output: `[I, V(HC), IV, V, I(PAC)]`

- motivic repetition model : piece at the note level $->$ material markers

  - example output: `["a","b","c","a","b","c","d","e","a","b","c"]`

- *form structure model : (material marker, harmony, cadence) $->$ FormTree*
  - example input: 
    
    `{a ⟦I-V None⟧} + {b ⟦I-III None⟧} + {a ⟦VI-II None⟧} + {b ⟦VI-III None⟧}`
  we want to say that this is the same idea expressed in different harmonic context
  - example output:
    ```
    Presentation <b.i. := "a" + "b" > 
          (idea usedOn ⟦I-V None⟧+⟦I-III None⟧)
          (idea usedOn ⟦VI-II None⟧+⟦VI-III None⟧)
    ```
== The problem of the form structure inference
  _We want to describe the input in terms of formal units and variable binding in a compact way_

  
  
  - Formal function imposes constraints on what kind of analysis is possible 
    - The term `(Presentation ideaBinding unit1 unit2)` entails that 
      - unit1 begins on I and 
      - the idea of unit1 and unit2 are the same
  - Description length impose a ranking on alternative analysis (so the model should prefer the third instead of the first). 
    - in general we can costs on the "operations" e.g. make "catch-all" merge rule such as `Concatenate` costly so the model will prefer to minimize their usage 

    - the trivial description
      ``` 
          = {a ⟦I-V None⟧} + {b ⟦I-III None⟧} + {a ⟦VI-II None⟧} + {b ⟦VI-III None⟧}
      ```

    - a short description
      ```
          = (idea usedOn ⟦I-V None⟧+⟦I-III None⟧) + (idea usedOn ⟦VI-II None⟧+⟦VI-III None⟧)
              where idea := "a" + "b" 
      ```

    - a short description using formal functions
      ```
          = Presentation <b.i. := "a" + "b" > 
              (idea usedOn ⟦I-V None⟧+⟦I-III None⟧)
              (idea usedOn ⟦VI-II None⟧+⟦VI-III None⟧)
      ```
=== The strategy
- we represent form analysis as a term (of a recursive type).
- [mostly music-theoretical] we define term rewriting rules encoding music theoretical knowledge on form. 

- we search for the smallest equivalent term for the input (reachable by the collection of rewrite rules). [mostly mathematical & programming] 

#pagebreak()
== Current prototype
=== Represent analysis as a term

Goals:
- we want to be able to recover the original surface (lossless encoding)
- we want to factor out formal repeats (compressible)
- we want the AST to be recursive, sentence and period should take FormalUnit as arguments (recursive)

The main AST
```hs
data FormalUnit
  = Leaf Idea PhraseParam
  | RefFormalUnit String
  | UseIdeaWith Idea PhraseParam
  | Sentence IdeaBinding FormalUnit FormalUnit
  | Period FormalUnitBinding FormalUnit FormalUnit
  | Presentation IdeaBinding FormalUnit FormalUnit
  | Continuation FormalUnit FormalUnit
  | Concatenate FormalUnit FormalUnit
  | ...

```

Auxillary definitions
```
data CadenceStrength = Weak | Strong | None 
data Harmony = I | II | III | IV | V | VI | VII 
data Idea
  = Label String
  | Concat Idea Idea
  | RefIdea String

data PhraseParam
  = Param [Harmony] CadenceStrength
  | ConcatParam PhraseParam PhraseParam

data IdeaBinding = BindIdea String Idea 
data FormalUnitBinding = BindFormalUnit String FormalUnit 
```

Note that FormalUnit is now a recursive AST

=== Example of Rewriting rules

  ```
  premises
        match = Concatenate x y
        IdeaOf x = IdeaOf y
        StartingHarmonyOf x = I
    
  conclusions
        match ~>
            (Presentation 
                (BindIdea "b.i." (IdeaOf x)) 
                (UseIdeaWith (RefIdea "b.i.") (GetParam x)) 
                (UseIdeaWith (RefIdea "b.i.") (GetParam y)) 
            )
  ```
#pagebreak()
#include("output.typ")