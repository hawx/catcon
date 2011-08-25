# CatCon

A (toy) concatenative language built in Ruby. It uses a single stack, that stack is 
taken by functions by default populated
by the command line input. It then runs through the program vertically executing lines
as required to produce an output.

     25 10 :* 50 :+ :PRINT

would print (25 * 10) + 50, which is 300
   
     25 10 :* 50 :+ 300 :EQ? :PRINT

would print true as 300 is EQ? (equal) to 300. To really understand what is happening
take it step by step.
   
     []           # program begins with empty stack
     [25]         # 25 is pushed on to the stack
     [10, 25]     # 10 is pushed on
     [250]        # :* takes top two items on the stack and mulitplies them
     [50, 250]    # 50 is pushed on
     [300]        # :+ takes the top two items and adds them together
     [300, 300]   # 300 is pushed on
     [true]       # :eq? takes the top two items and checks whether they are equal
     #=> true
     [true]       # :PRINT takes the top item and prints it to STDERR leaving the item

To define functions use the :DEF function.

    :DEFINE SQUARE :DUP :*
    
    5 :SQUARE
    
    [5]    # 5 pushed on to the stack
    [5, 5] # :DUP adds a copy of the top item to the top of the stack
    [25]   # :* takes the top two items and squares them


## Flow Control

The :IF function takes the top item from the stack and tests whether it is `true` or 
`false`, if `true` ...

    300 25 10 * 50 + :EQ? ["300 = 300" :PRINT] [] :IF
    
    [300]
    [25, 300]                           # :*
    [250, 300]
    [300, 300]                          # :+
    [true]                              # :EQ?
    [["300 = 300", :PRINT], true]
    [[], ["300 = 300", :PRINT], true]
    #=> "300 = 300"
    ["300 = 300"]
    
    
    
    