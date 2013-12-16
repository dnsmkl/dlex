module utils.exception_ctor_mixin;



/** Template mixin to be used as a body of custom exception class

	Examples:
	---
	import utils.exception_ctor_mixin;
	class MyException : Exception { mixin ExceptionCtorMixin; }
	---

	See also: http://forum.dlang.org/thread/mailman.778.1287745259.858.digitalmars-d-learn@puremagic.com#post-i9sg2a:24ls:241:40digitalmars.com
*/
public mixin template ExceptionCtorMixin() {
    this(
    	string msg
    	, string file = __FILE__
    	, size_t line = __LINE__
    	, Throwable next = null
	)
	{
        super(msg, file, line, next);
    }
}
