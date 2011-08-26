# Catcon SPEC

This specification provides an outline for Catcon's basic functionality. It 
also acts as the documentation for Catcon.


# Types

__NOTE:__ This is merely a reference for the future as I haven't implemented it 
properly yet.

Catcon consists of four basic types:

`bool`
  A boolean value either `true` or `false`
  
`num`
  A generic number
  
`char`
  A unicode character representation
  
`list`
  A collection of items of any type


# Functions

## How To Read

Function signatures are given in the following style

    :swap (a b) -> (b a)
      Swaps the top two items on the stack

The first line gives the name and the way the stack is manipulated, here for swap
it shows the two items changing places, it also names them `a` and `b` as it will
swap any object regardless of type. If we looked at `:sub` it would show 
`(num num) -> (num)` as only `num`s can be operated on, and it also shows that the
two items will be replaced by the single result. The remaining lines give a 
description of the function.

## Stack Operations

:pop (a) -> ()
  Removes the top item on the stack.
  
:dup (a) -> (a a)
  Pushes a duplicate of the top item of the stack to the stack.
  
:swap (a b) -> (b a)
  Swaps the top two items on the stack.

:drop (...) -> ()
  Removes all items from the stack.
  
:stk\_size () -> (num)
  Pushes a `num` of the size of the stack before it was added.
  
## Arithmetic Operations

:prod (num num) -> (num)
  Calculates the product of the top two items on the stack, replacing them with 
  the result. {Aliased as :*}
  
:add (num num) -> (num)
  Adds the top two items on the stack, replacing them with the result. {Aliased as :+}
  
:sub (num num) -> (num)
  Subtracts the top two items on the stack. {Aliased as :-}
  
:div (num num) -> (num)
  Divides the top two items on the stack. {Aliased as :/}
  
:mod (num num) -> (num)
  Calculates the modulus of the top two items on the stack. {Aliased as :%}
  
## Boolean Operations

:or (bool bool) -> (bool)
  Computes the boolean 'or' of the top two values.
  
:and (bool bool) -> (bool)
  Computes the boolean 'and' of the top two values.
  
## Comparative Operations

:eq? (a b) -> (bool)
  Compares top two items for equality. {Aliased as :=}
  
:gt? (a b) -> (bool)
  Tests whether the top stack item is greater than the second item. {Aliased as :>}
  
:lt? (a b) -> (bool)
  Tests whether the top stack item is less than the second item. {Aliased as :<}
  
## Others

:define (stm str) -> ()
  Defines a new function with the name given and the body given by the statement.
  
    "square" [
      :dup :*
    ] :define
    
    5 :sq  #=> 25

:if (stm stm bool) -> ()
  Conditionally evaluates one of two statements, if the condition is true the top 
  statement is evaluated (with the condition being the third item on the stack), if
  the condition is false the second statement is evaluated.
  
    4 3 :eq?
    ["4 is not equal to 3!" :print]
    ["4 is equal to 3?" :print]
    :if  #=> "4 is not equal to 3!"
