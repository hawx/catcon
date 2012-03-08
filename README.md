# CatCon

A (toy) [concatenative language][caten] built in Ruby. It is [stack based][stack]
so named variables are not available (though named functions are, though
functions which return a signle value are).

     25 10 * 50 + print
     ;=> 300
     ; in other languages it's probably written like this
     ; print((25 * 10) + 50)

     25 10 * 50 + 300 eq? print
     ;=> true
     ; as 300 == 300

would print true as 300 is equal (`#eq?`) to 300. To really understand what is happening
take it step by step.

     []           ; program begins with empty stack
     [25]         ; 25 is pushed on to the stack
     [25, 10]     ; 10 is pushed on
     [250]        ; #* takes top two items on the stack and multiplies them
     [250, 50]    ; 50 is pushed on
     [300]        ; #+ takes the top two items and adds them together
     [300, 300]   ; 300 is pushed on
     [true]       ; #eq? takes the top two items and checks whether they are equal
     ;=> true     ; #print takes the top item and prints it to STDERR

## Defining Functions

To define functions use the `#define` function.

    "sq" [
      dup *
    ] define

    5 sq print
    ;=> 25
    ; [5]    ; 5 pushed on to the stack
    ; [5, 5] ; #dup adds a copy of the top item to the top of the stack
    ; [25]   ; #* takes the top two items and multiplies them

Note that to name the function a string was used, not an identifier as that
would have meant the function `#sq` was called, which didn't exist until it was
`#define`d

## Flow Control

The `#if` function takes the top item from the stack and tests whether it is `true` or
`false`, if `true` it evaluates the second item on the stack, if `false` it evaluates
the third item.

    true
    ["It was false" print]
    ["It was true" print]
    ifelse
    ;=> "It was true"
    ;
    ; [true]
    ; [true, ["It was false", print]]
    ; [true, ["It was false", print], ["It was true", print]]


    300 25 10 * 50 + eq?
    ["300 = 300" print] if

    ; [300]
    ; [25, 300]                           ; #*
    ; [250, 300]
    ; [300, 300]                          ; #+
    ; [true]                              ; #eq?
    ; [["300 = 300", print], true]
    ; [[], ["300 = 300", print], true]
    ; ["300 = 300"]


## Delayed Evaluation

Wrapping a set of instructions with square brackets (`[` and `]`) prevents them from
being evaluated immediately. These are used for certain functions, `#if` and `#define`
for instance, to execute a statement use the `#call` function:

    1 2 [swap 1 +] call eq?

    ; [1]
    ; [2, 1]
    ; [[swap, 1, +], 2, 1]
    ; [1, 2] -> [1, 1, 2] -> [2, 2]
    ; [true]

For a single function it is a bit of a pain having to wrap it in `[` and `]` so
a shortcut is available, prefix the function name with a semi-colon,

    1 :inc 5 times

    ; [1]
    ; [1, [inc]]
    ; [1, [inc], 5]
    ; [6]




[caten]: http://en.wikipedia.org/wiki/Concatenative_programming_language "Concatenative programming language"
[stack]: http://en.wikipedia.org/wiki/Stack-based "Stack based programming language"
