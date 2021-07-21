Repository for assignment 2 in CASPL university course.

In this assignment, we implemented a big integer calculator purely in x86 assembly and some basic C standard library functions (like `malloc` and `free`).
In _big integer_, we mean an integer with an unbounded value.
Only the tests were written in C.

The big integers were reprsented in a linked list of bytes, in order from the least significant, the head, to the most significant, the tail.

The input to the calculator was text from the standard input.
The format was RPN (Reverse Polish notation),
thus we had to keep a stack of the numbers and operators of the input and results.

In the implementation, we decided to spice things up a bit.
We decided to model the software in an object oriented way, no polymorphism needed (and that's a relief).
Therefore, we implemented sturcutres with functions and created instances of the structures and call their methods.
I think the class model is not synchronized with the implementation,
but nonetheless it is still a good indicator for the general architecture. 

I (boaz) also wanted to try some crazy stuff with macros and assembler features like the macro context stack.
The other agreed to this and it was fine in the end.
The macros make the code look like some frankenstein mix between x86 assembly and C.
You'd be the judge of what turned out in the end.

All of the assignments descriptions in this course can be found [here](https://www.cs.bgu.ac.il/~caspl202/Assignments).
