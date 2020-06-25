# x86_Indefinitely_long_number_Multiplier
Code that multiplies indefinitely long series of  numbers. The length of the numbers can be chosen in the code.
The arcitecture is x86, but the multiplication happens on byte to byte basis. 
Using a fairly creative soluting to resolve the carry problem (the carry from the lower byte addition is added to the higher part of the multiplication result).
Compile and link as you wish, but usual use would be:
as multiply.s -o multiply.o
ld multiply.o -o multiply
./multiply < input_numbers
