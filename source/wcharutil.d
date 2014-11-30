// License: Public Domain

module wcharutil;

import std.utf;
import std.traits;

wchar[] toWString(S)(in S s)
    if ((is(S C : C[]) || is(S C : C*)) && isSomeChar!C)
{
    static if (!isStaticArray!S)
        if (s is null)
            return null;
    size_t p;
    static if (isArray!S)
        p = s.length;
    else
        for (; s[p]; p++) {}
    return cast(typeof(return)) toUTF16(s[0..p]);
}

unittest
{
    import std.typetuple;

	foreach (C; TypeTuple!(char, wchar, dchar))
	{
        C[5] s;
        s[] = '\0';
        assert(toWString(s) == "\0\0\0\0\0"w);
        assert(toWString(s.ptr) == ""w);
        s = "123\0""4";
        assert(toWString(s) == "123\0"w"4"w);
        assert(toWString(s.ptr) == "123"w);
        s = "abcde";
        assert(toWString(s) == "abcde"w);
        s = "abcd\0";
        assert(toWString(s.ptr) == "abcd"w);

        immutable(C)[] s1 = null;
        assert(toWString(s1) is null);

        immutable(C)[] s2 = "abc";
        assert(toWString(s2) == "abc"w);
        assert(toWString(s2.ptr) == "abc"w);
        
        immutable(C)[] s3 = "абвгд";
        assert(toWString(s3) == "абвгд"w);
        assert(toWString(s3.ptr) == "абвгд"w);
    }
}

const(wchar)* toWStringz(S)(in S s)
    if ((is(S C : C[]) || is(S C : C*)) && isSomeChar!C)
{
    static if (!isStaticArray!S)
        if (s is null)
            return null;
    size_t p;
    static if (isArray!S)
        for (; p < s.length && s[p]; p++) {}
    else
        for (; s[p]; p++) {}
    return cast(typeof(return)) toUTF16z(s[0..p]);
}

unittest
{
    import std.typetuple;
    import std.stdio;

	foreach (C; TypeTuple!(char, wchar, dchar))
	{
        C[5] s;
        s[] = '\0';
        assert(toWStringz(s)[0] == '\0');
        assert(toWStringz(s.ptr)[0] == '\0');
        s = "123\0\0";
        assert(toWStringz(s)[0..4] == "123\0"w);
        assert(toWStringz(s.ptr)[0..4] == "123\0"w);

        s = "abcde";
        assert(toWStringz(s)[0..6] == "abcde\0"w);
        s = "abcd\0";
        assert(toWStringz(s.ptr)[0..5] == "abcd\0"w);

        immutable(C)[] s1 = null;
        assert(toWStringz(s1) is null);

        immutable(C)[] s2 = "abc";
        assert(toWStringz(s2)[0..4] == "abc\0"w);
        assert(toWStringz(s2.ptr)[0..4] == "abc\0"w);
        
        immutable(C)[] s3 = "абвгд";
        assert(toWStringz(s3)[0..6] == "абвгд\0"w);
        assert(toWStringz(s3.ptr)[0..6] == "абвгд\0"w);

    }
}
