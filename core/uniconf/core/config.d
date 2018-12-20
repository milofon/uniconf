/**
 * The module contains the objects and the properties of control functions
 *
 * Copyright: (c) 2015-2018, Milofon Project.
 * License: Subject to the terms of the BSD 3-Clause License, as written in the included LICENSE.md file.
 * Author: <m.galanin@milofon.pro> Maksim Galanin
 * Date: 2018-08-16
 */

module uniconf.core.config;

private
{
    import std.typecons : Nullable;
    import std.array : split, appender;

    import uninode.core;
    import uniconf.core.exception;
}

/**
 * Delimiter char for config path
 */
enum DELIMITER_CHAR = '.';
/**
 * Default value for not object value
 */
enum DEFAULT_FIELD_NAME = "v";


/**
 * Implementation Config
 */
struct Config
{
@safe:
    /**
     *Internal implementation UniNodeImpl
     */
    UniNodeImpl!Config node;

    alias node this;

    /**
     * Construct Config from val
     *
     * Params:
     * val = value
     */
    this(V)(V val) inout
    {
        node = UniNodeImpl!Config(val);
    }


    @safe unittest
    {
        auto c = Config(1);
        auto ic = immutable(Config)(1);
        auto cc = const(Config)(1);
    }

    /**
     * Get the value of the node
     *
     * Example
     * ---
     * node.get!int;
     * ---
     */
    inout(Nullable!T) get(T)() inout
        if (isUniNodeType!(T, Config))
    {
        return getFrom!(T)(&this);
    }


    @safe unittest
    {
        auto node = Config(1);
        assert(node.get!string.isNull);
        assert(!node.get!int.isNull);
    }

    /**
     * Get the node if the specified path is not a node
     *
     * Params:
     *
     * path = The path to the desired site
     *
     * Example:
     * ---
     * node.get!int("foo.bar");
     * ---
     */
    inout(Nullable!T) get(T)(string path) inout
        if (isUniNodeType!(T, Config) || is(T == Config))
    {
        return getFrom!(T)(findNode(path));
    }


    @safe unittest
    {
        mixin(SimpleConfigs);
        assert(root.get!int("obj.one") == 1);
        assert(root.get!int("obj.two") == 2);
        assert(root.get!int("obj.tree").isNull);

        auto sub = root.get!Config("obj").get;
        assert(sub.isObject);
        assert(sub.get!int("one") == 1);
    }


    inout(T) getOrEnforce(T)(lazy string msg) inout
    {
        return getOrEnforceFrom!T(&this, msg);
    }


    @safe unittest
    {
        auto node = Config(1);

        bool isEx;
        try
            assert(node.getOrEnforce!string("not found") == "one");
        catch (ConfigException e)
            isEx = true;
        assert(isEx);
    }


    inout(T) getOrEnforce(T)(string path, lazy string msg) inout
    {
        return getOrEnforceFrom!(T)(findNode(path), msg);
    }


    @safe unittest
    {
        mixin(SimpleConfigs);
        assert(root.getOrEnforce!int("obj.one", "not found") == 1);
        bool isEx;
        try
            assert(root.getOrEnforce!int("obj.four", "not found") == 4);
        catch (ConfigException e)
            isEx = true;
        assert(isEx);
    }

    /**
     * Get the value, otherwise return the default value
     *
     * Params:
     *
     * alt = Default value
     *
     * Example:
     * ---
     * getOrElse(1);
     * ---
     */
    inout(T) getOrElse(T)(T alt) inout
        if (isUniNodeType!(T, Config))
    {
        return getOrElseFrom!T(&this, alt);
    }


    @safe unittest
    {
        auto node = Config(1);
        assert(node.getOrElse!int(2) == 1);
        assert(node.getOrElse!string("one") == "one");
    }

    /**
     * Get the node at the specified path, or return to the default value
     *
     * Params:
     *
     * path = The path to the desired site
     * alt  = Default value
     *
     * Example:
     * ---
     * getOrElse("foo", 1);
     * ---
     */
    inout(T) getOrElse(T)(string path, T alt) inout
        if (isUniNodeType!(T, Config) || is(T == Config))
    {
        return getOrElseFrom!(T)(findNode(path), alt);
    }


    @safe unittest
    {
        mixin(SimpleConfigs);
        assert(root.getOrElse!int("obj.one", 2) == 1);
        assert(root.getOrElse!int("obj.two", 3) == 2);
        assert(root.getOrElse!string("obj.one", "one") == "one");
    }

    /**
     * Checking for the presence of the node in the specified path
     *
     * It the node is an object, the we try to find the embedded objects in the specified path
     *
     * Params:
     *
     * path = The path to the desired site
     */
    inout(Config)* opBinaryRight(string op)(string key) inout if (op == "in")
    {
        return findNode(key);
    }


    @safe unittest
    {
        mixin(SimpleConfigs);
        assert("obj.one" in root);
        assert("obj.two" in root);
        assert("obj.tree" !in root);
    }

    /**
     * Convert to array of config on the specified path
     *
     * Params:
     *
     * path = The path to the desired site
     *
     * Example:
     * ---
     * getArray("services");
     * ---
     */
    Config[] getArray(string path)
    {
        return getArrayFrom(findNode(path));
    }


    @safe unittest
    {
        mixin(SimpleConfigs);
        auto arr = root.getArray("arr");
        assert(arr.length == 3);
        assert(arr == [Config(3), Config(4), Config(5)]);
        assert(root.getArray("obj.one").length == 1);
    }

    /**
     * Convert to array of config on the node
     *
     * Example
     * ---
     * node.getArray();
     * ---
     */
    Config[] getArray()
    {
        return getArrayFrom(&this);
    }


    @safe unittest
    {
        mixin(SimpleConfigs);
        assert(root.getArray("arr").length == 3);
    }

    /**
     * Convert to associative array of object properties in the node
     *
     * Params:
     *
     * path = The path to the desired site
     *
     * Example:
     * ---
     * toObject();
     * ---
     */
    Config[string] getObject()
    {
        return getObjectFrom(&this, DEFAULT_FIELD_NAME);
    }


    @safe unittest
    {
        mixin(SimpleConfigs);
        assert("obj" in root.getObject);
        assert("arr" in root.getObject);
    }

    /**
     * Convert to associative array of object config in the node
     *
     * Params:
     *
     * path = The path to the desired site
     *
     * Example:
     * ---
     * toObject();
     * ---
     */
    Config[string] getObject(string path)
    {
        return getObjectFrom(findNode(path), DEFAULT_FIELD_NAME);
    }


    @safe unittest
    {
        mixin(SimpleConfigs);
        assert("one" in root.getObject("obj"));
        assert("two" in root.getObject("obj"));
    }

    /**
     * Recursive merge properties
     *
     * When the merger is not going to existing nodes
     * If the parameter is an array, it will their concatenation
     *
     * Params:
     *
     * src = Source properties
     */
    Config opBinary(string op)(Config src) if ("~" == op)
    {
        if (src.isNull)
            return this; // bitcopy this

        if (this.isNull)
            return src; //bintcopy src

        void mergeNode(ref Config dst, ref Config src) @safe
        {
            if (dst.isNull)
            {
                if (src.isObject)
                    dst = Config.emptyObject;

                if (src.isArray)
                    dst = Config.emptyArray;
            }

            if (dst.isObject && src.isObject)
            {
                foreach (string key, ref Config ch; src)
                {
                    if (auto tg = key in dst)
                        mergeNode(*tg, ch);
                    else
                        dst[key] = ch;
                }
            }
            else if (dst.isArray && src.isArray)
            {
                dst = Config(dst.getArray ~ src.getArray);
            }
        }

        Config ret;
        mergeNode(ret, this);
        mergeNode(ret, src);
        return ret;
    }


    @safe unittest
    {
        mixin(SimpleConfigs);
        auto node = Config(["five": Config(5)]);
        Config root2 = Config(["obj": node, "arr": Config([Config(5)])]);
        Config nilRoot = Config(null);

        assert((root ~ nilRoot).get!int("obj.one") == 1);
        assert((nilRoot ~ root).get!int("obj.one") == 1);

        auto res = root ~ root2;
        assert(res.get!Config("arr").length == 4);
        assert(res.get!int("obj.five") == 5);
    }


    string toString() const
    {
        return node.toString;
    }


private:


    inout(Nullable!T) getFrom(T)(inout(Config)* node) inout
    {
        if (node is null)
            return inout(Nullable!T).init;

        try
        {
            static if (is(T == Config))
                return inout(Nullable!T)(*node);
            else
                return inout(Nullable!T)(node.node.get!T);
        }
        catch (UniNodeException e)
            return inout(Nullable!T).init;
    }


    inout(T) getOrElseFrom(T)(inout(Config)* node, T alt) inout
    {
        if (node is null)
            return alt;

        auto val = getFrom!T(node);
        if (val.isNull)
            return alt;
        else
            return val.get;
    }


    inout(T) getOrEnforceFrom(T)(inout(Config)* node, lazy string msg) inout
    {
        () @trusted { enforceConfig(node, msg); } ();
        auto val = getFrom!T(node);
        () @trusted { enforceConfig(!val.isNull, msg); } ();
        return val.get;
    }


    Config[] getArrayFrom(Config* node) inout
    {
        auto ret = appender!(Config[]);
        if (node is null)
            return ret.data;

        if (node.isArray)
        {
            foreach(ref Config child; *node)
                ret.put(child);
        }
        else
            ret.put(*node);

        return ret.data;
    }


    Config[string] getObjectFrom(Config* node, string defKey) inout
    {
        Config[string] ret;
        if (node is null)
            return ret;

        if (node.isObject)
        {
            foreach (string key, ref Config child; *node)
                ret[key] = child;
        }
        else
            ret[defKey] = *node;

        return ret;
    }

    /**
     * Getting node in the specified path
     *
     * It the node is an object, the we try to find the embedded objects in the specified path
     *
     * Params:
     *
     * path = The path to the desired site
     */
    inout(Config)* findNode(string path) inout
    {
        auto names = path.split(DELIMITER_CHAR);

        inout(Config)* findPath(inout(Config)* node, string[] names) inout
        {
            if(names.length == 0)
                return node;

            immutable name = names[0];
            if (node.isObject)
                if (auto chd = name in (*node).node)
                    return findPath(chd, names[1..$]);

            return null;
        }

        if (names.length > 0)
            return findPath(&this, names);

        return null;
    }
}


private:


version(unittest)
{
    enum SimpleConfigs = q{
        auto chObj = Config(["one": Config(1), "two": Config(2)]);
        auto chArr = Config([Config(3), Config(4), Config(5)]);
        auto root = Config(["obj": chObj, "arr": chArr]);
    };
}

