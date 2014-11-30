/*
  Original code: http://farmanager.googlecode.com/svn/trunk/plugins/common/unicode/PluginSettings.hpp
  License: derived from original one without extra restriction
*/

module pluginsettings;

import farplugin;
import wcharutil;

import std.traits;
import core.stdc.string;
import core.sys.windows.windows;

enum bool isIntegralType(T) = isBoolean!T || is(T == long) || is(T == ulong) || is(T == int) || is(T == uint);

class PluginSettings
{
private:
    HANDLE handle;
    FARAPISETTINGSCONTROL SettingsControl;

public:

    this(ref const GUID guid, FARAPISETTINGSCONTROL SettingsControl)
    {
        this.SettingsControl = SettingsControl;
        handle = INVALID_HANDLE_VALUE;

        FarSettingsCreate settings={FarSettingsCreate.sizeof, guid, handle};
        if (SettingsControl(INVALID_HANDLE_VALUE,FAR_SETTINGS_CONTROL_COMMANDS.SCTL_CREATE,0,&settings))
            handle = settings.Handle;
    }

    ~this()
    {
        SettingsControl(handle,FAR_SETTINGS_CONTROL_COMMANDS.SCTL_FREE,0,null);
    }

    auto CreateSubKey(size_t Root, wstring Name)
    {
        FarSettingsValue value={FarSettingsValue.sizeof,Root,Name.toWStringz};
        return SettingsControl(handle,FAR_SETTINGS_CONTROL_COMMANDS.SCTL_CREATESUBKEY,0,&value);
    }

    auto OpenSubKey(size_t Root, wstring Name)
    {
        FarSettingsValue value={FarSettingsValue.sizeof,Root,Name.toWStringz};
        return SettingsControl(handle,FAR_SETTINGS_CONTROL_COMMANDS.SCTL_OPENSUBKEY,0,&value);
    }

    bool DeleteSubKey(size_t Root)
    {
        FarSettingsValue value={FarSettingsValue.sizeof,Root,null};
        return SettingsControl(handle,FAR_SETTINGS_CONTROL_COMMANDS.SCTL_DELETE,0,&value) ? true : false;
    }

    bool DeleteValue(size_t Root, wstring Name)
    {
        FarSettingsValue value={FarSettingsValue.sizeof,Root,Name.toWStringz};
        return SettingsControl(handle,FAR_SETTINGS_CONTROL_COMMANDS.SCTL_DELETE,0,&value) ? true : false;
    }

    wchar[] Get(size_t Root, wstring Name, wchar[] Default)
    {
        FarSettingsItem item={FarSettingsItem.sizeof,Root,Name.toWStringz,FARSETTINGSTYPES.FST_STRING};
        if (SettingsControl(handle,FAR_SETTINGS_CONTROL_COMMANDS.SCTL_GET,0,&item))
        {
            return item.String.toWString;
        }
        return Default;
    }

    void Get(size_t Root, wstring Name, wchar[] Value, wchar[] Default)
    {
        Get(Root, Name, Value.ptr, Value.length, Default);
    }

    void Get(size_t Root, wstring Name, wchar* Value, size_t Size, wchar[] Default)
    {
        lstrcpynW(Value, Get(Root,Name,Default).toWStringz, cast(int)Size);
    }

    T Get(T)(size_t Root, wstring Name, T Default)
        if (isIntegralType!T)
    {
        FarSettingsItem item={FarSettingsItem.sizeof,Root,Name.toWStringz,FARSETTINGSTYPES.FST_QWORD};
        if (SettingsControl(handle,FAR_SETTINGS_CONTROL_COMMANDS.SCTL_GET,0,&item))
        {
            return cast(T)item.Number;
        }
        return Default;
    }

    size_t Get(size_t Root, wstring Name, void[] Value)
    {
        return Get(Root, Name, Value.ptr, Value.length);
    }

    size_t Get(size_t Root, wstring Name, void* Value, size_t Size)
    {
        FarSettingsItem item={FarSettingsItem.sizeof,Root,Name.toWStringz,FARSETTINGSTYPES.FST_DATA};
        if (SettingsControl(handle,FAR_SETTINGS_CONTROL_COMMANDS.SCTL_GET,0,&item))
        {
            Size = (item.Data.Size>Size)?Size:item.Data.Size;
            memcpy(Value,item.Data.Data,Size);
            return Size;
        }
        return 0;
    }

    bool Set(size_t Root, wstring Name, in wchar[] Value)
    {
        return Set(Root, Name, Value.toWStringz);
    }

    bool Set(size_t Root, wstring Name, in wchar* Value)
    {
        FarSettingsItem item={FarSettingsItem.sizeof,Root,Name.toWStringz,FARSETTINGSTYPES.FST_STRING};
        item.String=Value;
        return SettingsControl(handle,FAR_SETTINGS_CONTROL_COMMANDS.SCTL_SET,0,&item)!=FALSE;
    }

    bool Set(T)(size_t Root, wstring Name, T Value)
        if (isIntegralType!T)
    {
        FarSettingsItem item={FarSettingsItem.sizeof,Root,Name.toWStringz,FARSETTINGSTYPES.FST_QWORD};
        item.Number=Value;
        return SettingsControl(handle,FAR_SETTINGS_CONTROL_COMMANDS.SCTL_SET,0,&item)!=FALSE;
    }

    bool Set(size_t Root, wstring Name, in void[] Value)
    {
        return Set(Root, Name, Value.ptr, Value.length);
    }

    bool Set(size_t Root, wstring Name, in void* Value, size_t Size)
    {
        FarSettingsItem item={FarSettingsItem.sizeof,Root,Name.toWStringz,FARSETTINGSTYPES.FST_DATA};
        item.Data.Size=Size;
        item.Data.Data=Value;
        return SettingsControl(handle,FAR_SETTINGS_CONTROL_COMMANDS.SCTL_SET,0,&item)!=FALSE;
    }
}
