module utils.str_format;



@safe nothrow pure
string hex(char c)
{
	char lowerBits = (c & 0x0F);
	char higherBits = (c >> 4);
	return "0x"~ hexDigit(higherBits) ~ hexDigit(lowerBits);
}
unittest
{
	assert(hex(0x00) == "0x00");
	assert(hex(0x0d) == "0x0D");
	assert(hex(0x10) == "0x10");
	assert(hex(0xAD) == "0xAD");
}


private
@safe nothrow pure
string hexDigit(char lowerBits)
{
	assert(lowerBits <= 0x0F);
	if(lowerBits < 10)
		lowerBits += '0';
	else
		lowerBits += 'A' - 10;
	return ""~lowerBits;
}
