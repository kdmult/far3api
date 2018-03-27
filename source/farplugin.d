/*
  Plugin API for Far Manager 3.0 build 5151
  License: Public Domain
*/

module farplugin;

import std.stdint;
import core.sys.windows.windows;

const FARMANAGERVERSION_MAJOR = 3;
const FARMANAGERVERSION_MINOR = 0;
const FARMANAGERVERSION_REVISION = 0;
const FARMANAGERVERSION_BUILD = 5151;
const FARMANAGERVERSION_STAGE = VERSION_STAGE.VS_RELEASE;

const CP_UNICODE    = cast(uintptr_t)1200;
const CP_REVERSEBOM = cast(uintptr_t)1201;
const CP_DEFAULT    = cast(uintptr_t)-1;
const CP_REDETECT   = cast(uintptr_t)-2;

alias FARCOLORFLAGS = ulong;
const FARCOLORFLAGS
    FCF_FG_4BIT = 0x0000000000000001UL,
    FCF_BG_4BIT = 0x0000000000000002UL,
    FCF_4BITMASK = FCF_FG_4BIT|FCF_BG_4BIT, // 0x0000000000000003UL

    FCF_RAWATTR_MASK = 0x000000000000FF00UL, // stored console attributes

    FCF_EXTENDEDFLAGS = ~FCF_4BITMASK, // 0xFFFFFFFFFFFFFFFCUL
    FCF_FG_BOLD = 0x1000000000000000UL,
    FCF_FG_ITALIC = 0x2000000000000000UL,
    FCF_FG_UNDERLINE = 0x4000000000000000UL,
    FCF_STYLEMASK = FCF_FG_BOLD|FCF_FG_ITALIC|FCF_FG_UNDERLINE, // 0x7000000000000000UL
    FCF_NONE = 0UL;

struct rgba { byte r, g, b, a; }

struct FarColor
{
    FARCOLORFLAGS Flags;
    union
    {
        COLORREF ForegroundColor;
        rgba ForegroundRGBA;
    }
    union
    {
        COLORREF BackgroundColor;
        rgba BackgroundRGBA;
    }
    void* Reserved;

	bool IsBg4Bit() const
	{
		return (Flags & FCF_BG_4BIT) != 0;
	}

	bool IsFg4Bit() const
	{
		return (Flags & FCF_FG_4BIT) != 0;
	}

	FarColor SetBg4Bit(bool Value)
	{
		Value? Flags |= FCF_BG_4BIT : Flags &= ~FCF_BG_4BIT;
		return this;
	}

	FarColor SetFg4Bit(bool Value)
	{
		Value? Flags |= FCF_FG_4BIT : Flags &= ~FCF_FG_4BIT;
		return this;
	}
}

const INDEXMASK = 0x0000000F;
const COLORMASK = 0x00FFFFFF;
const ALPHAMASK = 0xFF000000;

auto INDEXVALUE(ARG1)(ARG1 x) { return ((x)&INDEXMASK); }
auto COLORVALUE(ARG1)(ARG1 x) { return ((x)&COLORMASK); }
auto ALPHAVALUE(ARG1)(ARG1 x) { return ((x)&ALPHAMASK); }

auto IS_OPAQUE(ARG1)(ARG1 x) { return (ALPHAVALUE(x)==ALPHAMASK); }
auto IS_TRANSPARENT(ARG1)(ARG1 x) { return (!ALPHAVALUE(x)); }
void MAKE_OPAQUE(ARG1)(ref ARG1 x) { (x|=ALPHAMASK); }
void MAKE_TRANSPARENT(ARG1)(ref ARG1 x) { (x&=COLORMASK); }

alias COLORDIALOGFLAGS = ulong;
const COLORDIALOGFLAGS CDF_NONE = 0UL;

alias FARAPICOLORDIALOG = extern (Windows) BOOL function(
    in GUID* PluginId,
    COLORDIALOGFLAGS Flags,
    FarColor* Color);

alias FARMESSAGEFLAGS = ulong;
const FARMESSAGEFLAGS
    FMSG_WARNING             = 0x0000000000000001UL,
    FMSG_ERRORTYPE           = 0x0000000000000002UL,
    FMSG_KEEPBACKGROUND      = 0x0000000000000004UL,
    FMSG_LEFTALIGN           = 0x0000000000000008UL,
    FMSG_ALLINONE            = 0x0000000000000010UL,
    FMSG_MB_OK               = 0x0000000000010000UL,
    FMSG_MB_OKCANCEL         = 0x0000000000020000UL,
    FMSG_MB_ABORTRETRYIGNORE = 0x0000000000030000UL,
    FMSG_MB_YESNO            = 0x0000000000040000UL,
    FMSG_MB_YESNOCANCEL      = 0x0000000000050000UL,
    FMSG_MB_RETRYCANCEL      = 0x0000000000060000UL,
    FMSG_NONE                = 0UL;

alias FARAPIMESSAGE = extern (Windows) intptr_t function(
    in GUID* PluginId,
    in GUID* Id,
    FARMESSAGEFLAGS Flags,
    in wchar* HelpTopic,
    in wchar** Items,
    size_t ItemsNumber,
    intptr_t ButtonsNumber);

enum FARDIALOGITEMTYPES
{
    DI_TEXT                         =  0,
    DI_VTEXT                        =  1,
    DI_SINGLEBOX                    =  2,
    DI_DOUBLEBOX                    =  3,
    DI_EDIT                         =  4,
    DI_PSWEDIT                      =  5,
    DI_FIXEDIT                      =  6,
    DI_BUTTON                       =  7,
    DI_CHECKBOX                     =  8,
    DI_RADIOBUTTON                  =  9,
    DI_COMBOBOX                     = 10,
    DI_LISTBOX                      = 11,

    DI_USERCONTROL                  =255,
}

/*
   Check diagol element type has inputstring?
   (DI_EDIT, DI_FIXEDIT, DI_PSWEDIT, etc)
*/
BOOL  IsEdit(FARDIALOGITEMTYPES Type)
{
    with (FARDIALOGITEMTYPES)
        switch (Type)
        {
            case DI_EDIT:
            case DI_FIXEDIT:
            case DI_PSWEDIT:
            case DI_COMBOBOX:
                return TRUE;
            default:
                return FALSE;
        }
}

alias FARDIALOGITEMFLAGS = ulong;
const FARDIALOGITEMFLAGS
    DIF_BOXCOLOR              = 0x0000000000000200UL,
    DIF_GROUP                 = 0x0000000000000400UL,
    DIF_LEFTTEXT              = 0x0000000000000800UL,
    DIF_MOVESELECT            = 0x0000000000001000UL,
    DIF_SHOWAMPERSAND         = 0x0000000000002000UL,
    DIF_CENTERGROUP           = 0x0000000000004000UL,
    DIF_NOBRACKETS            = 0x0000000000008000UL,
    DIF_MANUALADDHISTORY      = 0x0000000000008000UL,
    DIF_SEPARATOR             = 0x0000000000010000UL,
    DIF_SEPARATOR2            = 0x0000000000020000UL,
    DIF_EDITOR                = 0x0000000000020000UL,
    DIF_LISTNOAMPERSAND       = 0x0000000000020000UL,
    DIF_LISTNOBOX             = 0x0000000000040000UL,
    DIF_HISTORY               = 0x0000000000040000UL,
    DIF_BTNNOCLOSE            = 0x0000000000040000UL,
    DIF_CENTERTEXT            = 0x0000000000040000UL,
    DIF_SEPARATORUSER         = 0x0000000000080000UL,
    DIF_SETSHIELD             = 0x0000000000080000UL,
    DIF_EDITEXPAND            = 0x0000000000080000UL,
    DIF_DROPDOWNLIST          = 0x0000000000100000UL,
    DIF_USELASTHISTORY        = 0x0000000000200000UL,
    DIF_MASKEDIT              = 0x0000000000400000UL,
    DIF_LISTTRACKMOUSE        = 0x0000000000400000UL,
    DIF_LISTTRACKMOUSEINFOCUS = 0x0000000000800000UL,
    DIF_SELECTONENTRY         = 0x0000000000800000UL,
    DIF_3STATE                = 0x0000000000800000UL,
    DIF_EDITPATH              = 0x0000000001000000UL,
    DIF_LISTWRAPMODE          = 0x0000000001000000UL,
    DIF_NOAUTOCOMPLETE        = 0x0000000002000000UL,
    DIF_LISTAUTOHIGHLIGHT     = 0x0000000002000000UL,
    DIF_LISTNOCLOSE           = 0x0000000004000000UL,
    DIF_EDITPATHEXEC          = 0x0000000004000000UL,
    DIF_HIDDEN                = 0x0000000010000000UL,
    DIF_READONLY              = 0x0000000020000000UL,
    DIF_NOFOCUS               = 0x0000000040000000UL,
    DIF_DISABLE               = 0x0000000080000000UL,
    DIF_DEFAULTBUTTON         = 0x0000000100000000UL,
    DIF_FOCUS                 = 0x0000000200000000UL,
    DIF_RIGHTTEXT             = 0x0000000400000000UL,
    DIF_WORDWRAP              = 0x0000000800000000UL,
    DIF_NONE                  = 0UL;

enum FARMESSAGE
{
    DM_FIRST                        = 0,
    DM_CLOSE                        = 1,
    DM_ENABLE                       = 2,
    DM_ENABLEREDRAW                 = 3,
    DM_GETDLGDATA                   = 4,
    DM_GETDLGITEM                   = 5,
    DM_GETDLGRECT                   = 6,
    DM_GETTEXT                      = 7,
    DM_KEY                          = 9,
    DM_MOVEDIALOG                   = 10,
    DM_SETDLGDATA                   = 11,
    DM_SETDLGITEM                   = 12,
    DM_SETFOCUS                     = 13,
    DM_REDRAW                       = 14,
    DM_SETTEXT                      = 15,
    DM_SETMAXTEXTLENGTH             = 16,
    DM_SHOWDIALOG                   = 17,
    DM_GETFOCUS                     = 18,
    DM_GETCURSORPOS                 = 19,
    DM_SETCURSORPOS                 = 20,
    DM_SETTEXTPTR                   = 22,
    DM_SHOWITEM                     = 23,
    DM_ADDHISTORY                   = 24,

    DM_GETCHECK                     = 25,
    DM_SETCHECK                     = 26,
    DM_SET3STATE                    = 27,

    DM_LISTSORT                     = 28,
    DM_LISTGETITEM                  = 29,
    DM_LISTGETCURPOS                = 30,
    DM_LISTSETCURPOS                = 31,
    DM_LISTDELETE                   = 32,
    DM_LISTADD                      = 33,
    DM_LISTADDSTR                   = 34,
    DM_LISTUPDATE                   = 35,
    DM_LISTINSERT                   = 36,
    DM_LISTFINDSTRING               = 37,
    DM_LISTINFO                     = 38,
    DM_LISTGETDATA                  = 39,
    DM_LISTSETDATA                  = 40,
    DM_LISTSETTITLES                = 41,
    DM_LISTGETTITLES                = 42,

    DM_RESIZEDIALOG                 = 43,
    DM_SETITEMPOSITION              = 44,

    DM_GETDROPDOWNOPENED            = 45,
    DM_SETDROPDOWNOPENED            = 46,

    DM_SETHISTORY                   = 47,

    DM_GETITEMPOSITION              = 48,
    DM_SETINPUTNOTIFY               = 49,
    DM_SETMOUSEEVENTNOTIFY          = DM_SETINPUTNOTIFY,

    DM_EDITUNCHANGEDFLAG            = 50,

    DM_GETITEMDATA                  = 51,
    DM_SETITEMDATA                  = 52,

    DM_LISTSET                      = 53,

    DM_GETCURSORSIZE                = 54,
    DM_SETCURSORSIZE                = 55,

    DM_LISTGETDATASIZE              = 56,

    DM_GETSELECTION                 = 57,
    DM_SETSELECTION                 = 58,

    DM_GETEDITPOSITION              = 59,
    DM_SETEDITPOSITION              = 60,

    DM_SETCOMBOBOXEVENT             = 61,
    DM_GETCOMBOBOXEVENT             = 62,

    DM_GETCONSTTEXTPTR              = 63,
    DM_GETDLGITEMSHORT              = 64,
    DM_SETDLGITEMSHORT              = 65,

    DM_GETDIALOGINFO                = 66,

    DM_GETDIALOGTITLE               = 67,

    DN_FIRST                        = 4096,
    DN_BTNCLICK                     = 4097,
    DN_CTLCOLORDIALOG               = 4098,
    DN_CTLCOLORDLGITEM              = 4099,
    DN_CTLCOLORDLGLIST              = 4100,
    DN_DRAWDIALOG                   = 4101,
    DN_DRAWDLGITEM                  = 4102,
    DN_EDITCHANGE                   = 4103,
    DN_ENTERIDLE                    = 4104,
    DN_GOTFOCUS                     = 4105,
    DN_HELP                         = 4106,
    DN_HOTKEY                       = 4107,
    DN_INITDIALOG                   = 4108,
    DN_KILLFOCUS                    = 4109,
    DN_LISTCHANGE                   = 4110,
    DN_DRAGGED                      = 4111,
    DN_RESIZECONSOLE                = 4112,
    DN_DRAWDIALOGDONE               = 4113,
    DN_LISTHOTKEY                   = 4114,
    DN_INPUT                        = 4115,
    DN_CONTROLINPUT                 = 4116,
    DN_CLOSE                        = 4117,
    DN_GETVALUE                     = 4118,
    DN_DROPDOWNOPENED               = 4119,
    DN_DRAWDLGITEMDONE              = 4120,

    DM_USER                         = 0x4000,
}

enum FARCHECKEDSTATE
{
    BSTATE_UNCHECKED = 0,
    BSTATE_CHECKED   = 1,
    BSTATE_3STATE    = 2,
    BSTATE_TOGGLE    = 3,
}

enum FARCOMBOBOXEVENTTYPE
{
    CBET_KEY         = 0x00000001,
    CBET_MOUSE       = 0x00000002,
}

alias LISTITEMFLAGS = ulong;
const LISTITEMFLAGS
    LIF_SELECTED           = 0x0000000000010000UL,
    LIF_CHECKED            = 0x0000000000020000UL,
    LIF_SEPARATOR          = 0x0000000000040000UL,
    LIF_DISABLE            = 0x0000000000080000UL,
    LIF_GRAYED             = 0x0000000000100000UL,
    LIF_HIDDEN             = 0x0000000000200000UL,
    LIF_DELETEUSERDATA     = 0x0000000080000000UL,
    LIF_NONE               = 0UL;

struct FarListItem
{
    LISTITEMFLAGS Flags;
    const(wchar)* Text;
    intptr_t[2] Reserved;
}

struct FarListUpdate
{
    size_t StructSize;
    intptr_t Index;
    FarListItem Item;
}

struct FarListInsert
{
    size_t StructSize;
    intptr_t Index;
    FarListItem Item;
}

struct FarListGetItem
{
    size_t StructSize;
    intptr_t ItemIndex;
    FarListItem Item;
}

struct FarListPos
{
    size_t StructSize;
    intptr_t SelectPos;
    intptr_t TopPos;
}

alias FARLISTFINDFLAGS = ulong;
const FARLISTFINDFLAGS
    LIFIND_EXACTMATCH = 0x0000000000000001UL,
    LIFIND_NONE       = 0UL;

struct FarListFind
{
    size_t StructSize;
    intptr_t StartIndex;
    const(wchar)* Pattern;
    FARLISTFINDFLAGS Flags;
}

struct FarListDelete
{
    size_t StructSize;
    intptr_t StartIndex;
    intptr_t Count;
}

alias FARLISTINFOFLAGS = ulong;
const FARLISTINFOFLAGS
    LINFO_SHOWNOBOX             = 0x0000000000000400UL,
    LINFO_AUTOHIGHLIGHT         = 0x0000000000000800UL,
    LINFO_REVERSEHIGHLIGHT      = 0x0000000000001000UL,
    LINFO_WRAPMODE              = 0x0000000000008000UL,
    LINFO_SHOWAMPERSAND         = 0x0000000000010000UL,
    LINFO_NONE                  = 0UL;

struct FarListInfo
{
    size_t StructSize;
    FARLISTINFOFLAGS Flags;
    size_t ItemsNumber;
    intptr_t SelectPos;
    intptr_t TopPos;
    intptr_t MaxHeight;
    intptr_t MaxLength;
}

struct FarListItemData
{
    size_t StructSize;
    intptr_t Index;
    size_t DataSize;
    void* Data;
}

struct FarList
{
    size_t StructSize;
    size_t ItemsNumber;
    FarListItem* Items;
}

struct FarListTitles
{
    size_t StructSize;
    size_t TitleSize;
    const(wchar)* Title;
    size_t BottomSize;
    const(wchar)* Bottom;
}

struct FarDialogItemColors
{
    size_t StructSize;
    ulong Flags;
    size_t ColorsCount;
    FarColor* Colors;
}

struct FAR_CHAR_INFO
{
    wchar Char;
    FarColor Attributes;

    static FAR_CHAR_INFO make(wchar Char, in FarColor Attributes)
    {
        return FAR_CHAR_INFO(Char, cast(FarColor) Attributes);
    }
}

struct FarDialogItem
{
    FARDIALOGITEMTYPES Type;
    intptr_t X1,Y1,X2,Y2;
    union
    {
        intptr_t Selected;
        FarList* ListItems;
        FAR_CHAR_INFO* VBuf;
        intptr_t Reserved0;
    }
    const(wchar)* History;
    const(wchar)* Mask;
    FARDIALOGITEMFLAGS Flags;
    const(wchar)* Data;
    size_t MaxLength; // terminate 0 not included (if == 0 string size is unlimited)
    intptr_t UserData;
    intptr_t[2] Reserved;
}

struct FarDialogItemData
{
    size_t StructSize;
    size_t PtrLength;
    wchar* PtrData;
}

struct FarDialogEvent
{
    size_t StructSize;
    HANDLE hDlg;
    intptr_t Msg;
    intptr_t Param1;
    void* Param2;
    intptr_t Result;
}

struct OpenDlgPluginData
{
    size_t StructSize;
    HANDLE hDlg;
}

struct DialogInfo
{
    size_t StructSize;
    GUID Id;
    GUID Owner;
}

struct FarGetDialogItem
{
    size_t StructSize;
    size_t Size;
    FarDialogItem* Item;
}

alias FARDIALOGFLAGS = ulong;
const FARDIALOGFLAGS
    FDLG_WARNING             = 0x0000000000000001UL,
    FDLG_SMALLDIALOG         = 0x0000000000000002UL,
    FDLG_NODRAWSHADOW        = 0x0000000000000004UL,
    FDLG_NODRAWPANEL         = 0x0000000000000008UL,
    FDLG_KEEPCONSOLETITLE    = 0x0000000000000010UL,
    FDLG_NONMODAL            = 0x0000000000000020UL,
    FDLG_NONE                = 0UL;

alias FARWINDOWPROC = extern (Windows) intptr_t function(HANDLE hDlg, intptr_t Msg, intptr_t Param1, void* Param2);

alias FARAPISENDDLGMESSAGE = extern (Windows) intptr_t function(HANDLE hDlg, intptr_t Msg, intptr_t Param1, void* Param2);

alias FARAPIDEFDLGPROC = extern (Windows) intptr_t function(HANDLE hDlg, intptr_t Msg, intptr_t Param1, void* Param2);

alias FARAPIDIALOGINIT = extern (Windows) HANDLE function(
    in GUID* PluginId,
    in GUID* Id,
    intptr_t X1,
    intptr_t Y1,
    intptr_t X2,
    intptr_t Y2,
    in wchar* HelpTopic,
    in FarDialogItem* Item,
    size_t ItemsNumber,
    intptr_t Reserved,
    FARDIALOGFLAGS Flags,
    FARWINDOWPROC DlgProc,
    void* Param);

alias FARAPIDIALOGRUN = extern (Windows) intptr_t function(HANDLE hDlg);

alias FARAPIDIALOGFREE = extern (Windows) void function(HANDLE hDlg);

struct FarKey
{
    WORD VirtualKeyCode;
    DWORD ControlKeyState;
}

alias MENUITEMFLAGS = ulong;
const MENUITEMFLAGS
    MIF_SELECTED   = 0x000000000010000UL,
    MIF_CHECKED    = 0x000000000020000UL,
    MIF_SEPARATOR  = 0x000000000040000UL,
    MIF_DISABLE    = 0x000000000080000UL,
    MIF_GRAYED     = 0x000000000100000UL,
    MIF_HIDDEN     = 0x000000000200000UL,
    MIF_NONE       = 0UL;

struct FarMenuItem
{
    MENUITEMFLAGS Flags;
    const(wchar)* Text;
    FarKey AccelKey;
    intptr_t UserData;
    intptr_t[2] Reserved;
}

alias FARMENUFLAGS = ulong;
const FARMENUFLAGS
    FMENU_SHOWAMPERSAND        = 0x0000000000000001UL,
    FMENU_WRAPMODE             = 0x0000000000000002UL,
    FMENU_AUTOHIGHLIGHT        = 0x0000000000000004UL,
    FMENU_REVERSEAUTOHIGHLIGHT = 0x0000000000000008UL,
    FMENU_CHANGECONSOLETITLE   = 0x0000000000000010UL,
    FMENU_NONE                 = 0UL;

alias FARAPIMENU = extern (Windows) intptr_t function(
    in GUID* PluginId,
    in GUID* Id,
    intptr_t X,
    intptr_t Y,
    intptr_t MaxHeight,
    const FARMENUFLAGS Flags,
    in wchar* Title,
    in wchar* Bottom,
    in wchar* HelpTopic,
    in FarKey* BreakKeys,
    intptr_t* BreakCode,
    in FarMenuItem* Item,
    size_t ItemsNumber);

alias PLUGINPANELITEMFLAGS = ulong;
const PLUGINPANELITEMFLAGS
    PPIF_SELECTED               = 0x0000000040000000UL,
    PPIF_PROCESSDESCR           = 0x0000000080000000UL,
    PPIF_NONE                   = 0UL;

struct FarPanelItemFreeInfo
{
    size_t StructSize;
    HANDLE hPlugin;
}

alias FARPANELITEMFREECALLBACK = extern (Windows) void function(
    void* UserData,
    in FarPanelItemFreeInfo* Info);

struct UserDataItem
{
    void* Data;
    FARPANELITEMFREECALLBACK FreeData;
}

struct PluginPanelItem
{
    FILETIME CreationTime;
    FILETIME LastAccessTime;
    FILETIME LastWriteTime;
    FILETIME ChangeTime;
    ulong FileSize;
    ulong AllocationSize;
    const(wchar)* FileName;
    const(wchar)* AlternateFileName;
    const(wchar)* Description;
    const(wchar)* Owner;
    const(wchar*)* CustomColumnData;
    size_t CustomColumnNumber;
    PLUGINPANELITEMFLAGS Flags;
    UserDataItem UserData;
    uintptr_t FileAttributes;
    uintptr_t NumberOfLinks;
    uintptr_t CRC32;
    intptr_t[2] Reserved;
}

struct FarGetPluginPanelItem
{
    size_t StructSize;
    size_t Size;
    PluginPanelItem* Item;
}

struct SortingPanelItem
{
	FILETIME CreationTime;
	FILETIME LastAccessTime;
	FILETIME LastWriteTime;
	FILETIME ChangeTime;
	ulong FileSize;
	ulong AllocationSize;
	const(wchar)* FileName;
	const(wchar)* AlternateFileName;
	const(wchar)* Description;
	const(wchar)* Owner;
	const(wchar*)* CustomColumnData;
	size_t CustomColumnNumber;
	PLUGINPANELITEMFLAGS Flags;
	UserDataItem UserData;
	uintptr_t FileAttributes;
	uintptr_t NumberOfLinks;
	uintptr_t CRC32;
	intptr_t Position;
	intptr_t SortGroup;
	uintptr_t NumberOfStreams;
	ulong StreamsSize;
}

alias PANELINFOFLAGS = ulong;
const PANELINFOFLAGS
    PFLAGS_SHOWHIDDEN         = 0x0000000000000001UL,
    PFLAGS_HIGHLIGHT          = 0x0000000000000002UL,
    PFLAGS_REVERSESORTORDER   = 0x0000000000000004UL,
    PFLAGS_USESORTGROUPS      = 0x0000000000000008UL,
    PFLAGS_SELECTEDFIRST      = 0x0000000000000010UL,
    PFLAGS_REALNAMES          = 0x0000000000000020UL,
    PFLAGS_PANELLEFT          = 0x0000000000000080UL,
    PFLAGS_DIRECTORIESFIRST   = 0x0000000000000100UL,
    PFLAGS_USECRC32           = 0x0000000000000200UL,
    PFLAGS_PLUGIN             = 0x0000000000000800UL,
    PFLAGS_VISIBLE            = 0x0000000000001000UL,
    PFLAGS_FOCUS              = 0x0000000000002000UL,
    PFLAGS_ALTERNATIVENAMES   = 0x0000000000004000UL,
    PFLAGS_SHORTCUT           = 0x0000000000008000UL,
    PFLAGS_NONE               = 0UL;

enum PANELINFOTYPE
{
    PTYPE_FILEPANEL                 = 0,
    PTYPE_TREEPANEL                 = 1,
    PTYPE_QVIEWPANEL                = 2,
    PTYPE_INFOPANEL                 = 3,
}

enum OPENPANELINFO_SORTMODES
{
    SM_DEFAULT                   =  0,
    SM_UNSORTED                  =  1,
    SM_NAME                      =  2,
    SM_EXT                       =  3,
    SM_MTIME                     =  4,
    SM_CTIME                     =  5,
    SM_ATIME                     =  6,
    SM_SIZE                      =  7,
    SM_DESCR                     =  8,
    SM_OWNER                     =  9,
    SM_COMPRESSEDSIZE            = 10,
    SM_NUMLINKS                  = 11,
    SM_NUMSTREAMS                = 12,
    SM_STREAMSSIZE               = 13,
    SM_FULLNAME                  = 14,
    SM_CHTIME                    = 15,

    SM_COUNT
}

struct PanelInfo
{
    size_t StructSize;
    HANDLE PluginHandle;
    GUID OwnerGuid;
    PANELINFOFLAGS Flags;
    size_t ItemsNumber;
    size_t SelectedItemsNumber;
    RECT PanelRect;
    size_t CurrentItem;
    size_t TopPanelItem;
    intptr_t ViewMode;
    PANELINFOTYPE PanelType;
    OPENPANELINFO_SORTMODES SortMode;
}

struct PanelRedrawInfo
{
    size_t StructSize;
    size_t CurrentItem;
    size_t TopPanelItem;
}

struct CmdLineSelect
{
    size_t StructSize;
    intptr_t SelStart;
    intptr_t SelEnd;
}

struct FarPanelDirectory
{
    size_t StructSize;
    const(wchar)* Name;
    const(wchar)* Param;
    GUID PluginId;
    const(wchar)* File;
}

const PANEL_NONE = cast(HANDLE)-1;
const PANEL_ACTIVE = cast(HANDLE)-1;
const PANEL_PASSIVE = cast(HANDLE)-2;
const PANEL_STOP = cast(HANDLE)-1;

enum FILE_CONTROL_COMMANDS
{
    FCTL_CLOSEPANEL                 = 0,
    FCTL_GETPANELINFO               = 1,
    FCTL_UPDATEPANEL                = 2,
    FCTL_REDRAWPANEL                = 3,
    FCTL_GETCMDLINE                 = 4,
    FCTL_SETCMDLINE                 = 5,
    FCTL_SETSELECTION               = 6,
    FCTL_SETVIEWMODE                = 7,
    FCTL_INSERTCMDLINE              = 8,
    FCTL_SETUSERSCREEN              = 9,
    FCTL_SETPANELDIRECTORY          = 10,
    FCTL_SETCMDLINEPOS              = 11,
    FCTL_GETCMDLINEPOS              = 12,
    FCTL_SETSORTMODE                = 13,
    FCTL_SETSORTORDER               = 14,
    FCTL_SETCMDLINESELECTION        = 15,
    FCTL_GETCMDLINESELECTION        = 16,
    FCTL_CHECKPANELSEXIST           = 17,
    FCTL_GETUSERSCREEN              = 19,
    FCTL_ISACTIVEPANEL              = 20,
    FCTL_GETPANELITEM               = 21,
    FCTL_GETSELECTEDPANELITEM       = 22,
    FCTL_GETCURRENTPANELITEM        = 23,
    FCTL_GETPANELDIRECTORY          = 24,
    FCTL_GETCOLUMNTYPES             = 25,
    FCTL_GETCOLUMNWIDTHS            = 26,
    FCTL_BEGINSELECTION             = 27,
    FCTL_ENDSELECTION               = 28,
    FCTL_CLEARSELECTION             = 29,
    FCTL_SETDIRECTORIESFIRST        = 30,
    FCTL_GETPANELFORMAT             = 31,
    FCTL_GETPANELHOSTFILE           = 32,
    FCTL_GETPANELPREFIX             = 34,
    FCTL_SETACTIVEPANEL             = 35,
}

alias FARAPITEXT = extern (Windows) void function(
    intptr_t X,
    intptr_t Y,
    in FarColor* Color,
    in wchar* Str);

alias FARAPISAVESCREEN = extern (Windows) HANDLE function(intptr_t X1, intptr_t Y1, intptr_t X2, intptr_t Y2);

alias FARAPIRESTORESCREEN = extern (Windows) void function(HANDLE hScreen);

alias FARAPIGETDIRLIST = extern (Windows) intptr_t function(
    in wchar* Dir,
    PluginPanelItem** pPanelItem,
    size_t* pItemsNumber);

alias FARAPIGETPLUGINDIRLIST = extern (Windows) intptr_t function(
    in GUID* PluginId,
    HANDLE hPanel,
    in wchar* Dir,
    PluginPanelItem** pPanelItem,
    size_t* pItemsNumber);

alias FARAPIFREEDIRLIST = extern (Windows) void function(PluginPanelItem* PanelItem, size_t nItemsNumber);

alias FARAPIFREEPLUGINDIRLIST = extern (Windows) void function(HANDLE hPanel, PluginPanelItem* PanelItem, size_t nItemsNumber);

alias VIEWER_FLAGS = ulong;
const VIEWER_FLAGS
    VF_NONMODAL              = 0x0000000000000001UL,
    VF_DELETEONCLOSE         = 0x0000000000000002UL,
    VF_ENABLE_F6             = 0x0000000000000004UL,
    VF_DISABLEHISTORY        = 0x0000000000000008UL,
    VF_IMMEDIATERETURN       = 0x0000000000000100UL,
    VF_DELETEONLYFILEONCLOSE = 0x0000000000000200UL,
    VF_NONE                  = 0UL;

alias FARAPIVIEWER = extern (Windows) intptr_t function(
    in wchar* FileName,
    in wchar* Title,
    intptr_t X1,
    intptr_t Y1,
    intptr_t X2,
    intptr_t Y2,
    VIEWER_FLAGS Flags,
    uintptr_t CodePage);

alias EDITOR_FLAGS = ulong;
const EDITOR_FLAGS
    EF_NONMODAL              = 0x0000000000000001UL,
    EF_CREATENEW             = 0x0000000000000002UL,
    EF_ENABLE_F6             = 0x0000000000000004UL,
    EF_DISABLEHISTORY        = 0x0000000000000008UL,
    EF_DELETEONCLOSE         = 0x0000000000000010UL,
    EF_IMMEDIATERETURN       = 0x0000000000000100UL,
    EF_DELETEONLYFILEONCLOSE = 0x0000000000000200UL,
    EF_LOCKED                = 0x0000000000000400UL,
    EF_DISABLESAVEPOS        = 0x0000000000000800UL,
    EF_OPENMODE_MASK         = 0x00000000F0000000UL,
    EF_OPENMODE_QUERY        = 0x0000000000000000UL,
    EF_OPENMODE_NEWIFOPEN    = 0x0000000010000000UL,
    EF_OPENMODE_USEEXISTING  = 0x0000000020000000UL,
    EF_OPENMODE_BREAKIFOPEN  = 0x0000000030000000UL,
    EF_OPENMODE_RELOADIFOPEN = 0x0000000040000000UL,
    EN_NONE                  = 0UL;

enum EDITOR_EXITCODE
{
    EEC_OPEN_ERROR          = 0,
    EEC_MODIFIED            = 1,
    EEC_NOT_MODIFIED        = 2,
    EEC_LOADING_INTERRUPTED = 3,
}

alias FARAPIEDITOR = extern (Windows) intptr_t function(
    in wchar* FileName,
    in wchar* Title,
    intptr_t X1,
    intptr_t Y1,
    intptr_t X2,
    intptr_t Y2,
    EDITOR_FLAGS Flags,
    int StartLine,
    int StartChar,
    uintptr_t CodePage);

alias FARAPIGETMSG = extern (Windows) const(wchar)* function(
    in GUID* PluginId,
    intptr_t MsgId);

alias FARHELPFLAGS = ulong;
const FARHELPFLAGS
    FHELP_NOSHOWERROR = 0x0000000080000000UL,
    FHELP_SELFHELP    = 0x0000000000000000UL,
    FHELP_FARHELP     = 0x0000000000000001UL,
    FHELP_CUSTOMFILE  = 0x0000000000000002UL,
    FHELP_CUSTOMPATH  = 0x0000000000000004UL,
    FHELP_GUID        = 0x0000000000000008UL,
    FHELP_USECONTENTS = 0x0000000040000000UL,
    FHELP_NONE        = 0UL;

alias FARAPISHOWHELP = extern (Windows) BOOL function(
    in wchar* ModuleName,
    in wchar* Topic,
    FARHELPFLAGS Flags);

enum ADVANCED_CONTROL_COMMANDS
{
    ACTL_GETFARMANAGERVERSION       = 0,
    ACTL_WAITKEY                    = 2,
    ACTL_GETCOLOR                   = 3,
    ACTL_GETARRAYCOLOR              = 4,
    ACTL_GETWINDOWINFO              = 6,
    ACTL_GETWINDOWCOUNT             = 7,
    ACTL_SETCURRENTWINDOW           = 8,
    ACTL_COMMIT                     = 9,
    ACTL_GETFARHWND                 = 10,
    ACTL_SETARRAYCOLOR              = 16,
    ACTL_REDRAWALL                  = 19,
    ACTL_SYNCHRO                    = 20,
    ACTL_SETPROGRESSSTATE           = 21,
    ACTL_SETPROGRESSVALUE           = 22,
    ACTL_QUIT                       = 23,
    ACTL_GETFARRECT                 = 24,
    ACTL_GETCURSORPOS               = 25,
    ACTL_SETCURSORPOS               = 26,
    ACTL_PROGRESSNOTIFY             = 27,
    ACTL_GETWINDOWTYPE              = 28,
}

enum FAR_MACRO_CONTROL_COMMANDS
{
    MCTL_LOADALL           = 0,
    MCTL_SAVEALL           = 1,
    MCTL_SENDSTRING        = 2,
    MCTL_GETSTATE          = 5,
    MCTL_GETAREA           = 6,
    MCTL_ADDMACRO          = 7,
    MCTL_DELMACRO          = 8,
    MCTL_GETLASTERROR      = 9,
    MCTL_EXECSTRING        = 10,
}

alias FARKEYMACROFLAGS = ulong;
const FARKEYMACROFLAGS
    KMFLAGS_SILENTCHECK         = 0x0000000000000001UL,
    KMFLAGS_NOSENDKEYSTOPLUGINS = 0x0000000000000002UL,
    KMFLAGS_ENABLEOUTPUT        = 0x0000000000000004UL,
    KMFLAGS_LANGMASK            = 0x0000000000000070UL, // 3 bits reserved for 8 languages
    KMFLAGS_LUA                 = 0x0000000000000000UL,
    KMFLAGS_MOONSCRIPT          = 0x0000000000000010UL,
    KMFLAGS_NONE                = 0UL;

enum FARMACROSENDSTRINGCOMMAND
{
    MSSC_POST              =0,
    MSSC_CHECK             =2,
}

enum FARMACROAREA
{
    MACROAREA_OTHER                      =   0,   // Reserved
    MACROAREA_SHELL                      =   1,   // File panels
    MACROAREA_VIEWER                     =   2,   // Internal viewer program
    MACROAREA_EDITOR                     =   3,   // Editor
    MACROAREA_DIALOG                     =   4,   // Dialogs
    MACROAREA_SEARCH                     =   5,   // Quick search in panels
    MACROAREA_DISKS                      =   6,   // Menu of disk selection
    MACROAREA_MAINMENU                   =   7,   // Main menu
    MACROAREA_MENU                       =   8,   // Other menus
    MACROAREA_HELP                       =   9,   // Help system
    MACROAREA_INFOPANEL                  =  10,   // Info panel
    MACROAREA_QVIEWPANEL                 =  11,   // Quick view panel
    MACROAREA_TREEPANEL                  =  12,   // Folders tree panel
    MACROAREA_FINDFOLDER                 =  13,   // Find folder
    MACROAREA_USERMENU                   =  14,   // User menu
    MACROAREA_SHELLAUTOCOMPLETION        =  15,   // Autocompletion list in command line
    MACROAREA_DIALOGAUTOCOMPLETION       =  16,   // Autocompletion list in dialogs
    MACROAREA_GRABBER                    =  17,   // Mode of copying text from the screen
    MACROAREA_DESKTOP                    =  18,   // Desktop

    MACROAREA_COMMON                     = 255,
}

enum FARMACROSTATE
{
    MACROSTATE_NOMACRO          = 0,
    MACROSTATE_EXECUTING        = 1,
    MACROSTATE_EXECUTING_COMMON = 2,
    MACROSTATE_RECORDING        = 3,
    MACROSTATE_RECORDING_COMMON = 4,
}

enum FARMACROPARSEERRORCODE
{
    MPEC_SUCCESS = 0,
    MPEC_ERROR   = 1,
}

struct MacroParseResult
{
    size_t StructSize;
    DWORD ErrCode;
    COORD ErrPos;
    const(wchar)* ErrSrc;
}

struct MacroSendMacroText
{
    size_t StructSize;
    FARKEYMACROFLAGS Flags;
    INPUT_RECORD AKey;
    const(wchar)* SequenceText;
}

alias FARADDKEYMACROFLAGS = ulong;
const FARADDKEYMACROFLAGS AKMFLAGS_NONE = 0UL;

alias FARMACROCALLBACK = extern (Windows) intptr_t function(void* Id, FARADDKEYMACROFLAGS Flags);

struct MacroAddMacro
{
    size_t StructSize;
    void* Id;
    const(wchar)* SequenceText;
    const(wchar)* Description;
    FARKEYMACROFLAGS Flags;
    INPUT_RECORD AKey;
    FARMACROAREA Area;
    FARMACROCALLBACK Callback;
    intptr_t Priority;
}

enum FARMACROVARTYPE
{
    FMVT_UNKNOWN                = 0,
    FMVT_INTEGER                = 1,
    FMVT_STRING                 = 2,
    FMVT_DOUBLE                 = 3,
    FMVT_BOOLEAN                = 4,
    FMVT_BINARY                 = 5,
    FMVT_POINTER                = 6,
    FMVT_NIL                    = 7,
    FMVT_ARRAY                  = 8,
    FMVT_PANEL                  = 9,
}

struct FarMacroValueBinary
{
    void* Data;
    size_t Size;
}

struct FarMacroValueArray
{
    FarMacroValue* Values;
    size_t Count;
}

struct FarMacroValue
{
    FARMACROVARTYPE Type = FARMACROVARTYPE.FMVT_NIL;
    union
    {
        long Integer;
        long Boolean;
        double Double;
        const(wchar)* String;
        void* Pointer;
        FarMacroValueBinary Binary;
        FarMacroValueArray Array;
    }

    this(int v)              { Type=FARMACROVARTYPE.FMVT_INTEGER; Integer=v; }
    this(uint v)             { Type=FARMACROVARTYPE.FMVT_INTEGER; Integer=v; }
    this(long v)             { Type=FARMACROVARTYPE.FMVT_INTEGER; Integer=v; }
    this(ulong v)            { Type=FARMACROVARTYPE.FMVT_INTEGER; Integer=v; }
    this(bool v)             { Type=FARMACROVARTYPE.FMVT_BOOLEAN; Boolean=v; }
    this(double v)           { Type=FARMACROVARTYPE.FMVT_DOUBLE; Double=v; }
    this(const(wchar)* v)  { Type=FARMACROVARTYPE.FMVT_STRING; String=v; }
    this(void* v)            { Type=FARMACROVARTYPE.FMVT_POINTER; Pointer=v; }
    this(ref const GUID v)   { Type=FARMACROVARTYPE.FMVT_BINARY; Binary.Data=cast(void*)&v; Binary.Size=GUID.sizeof; }
    this(FarMacroValue* arr,size_t count) { Type=FARMACROVARTYPE.FMVT_ARRAY; Array.Values=arr; Array.Count=count; }
}

struct FarMacroCall
{
    size_t StructSize;
    size_t Count;
    FarMacroValue* Values;
    extern (Windows) void function(void* CallbackData, FarMacroValue* Values, size_t Count) Callback;
    void* CallbackData;
}

struct FarGetValue
{
    size_t StructSize;
    intptr_t Type;
    FarMacroValue Value;
}

struct MacroExecuteString
{
    size_t StructSize;
    FARKEYMACROFLAGS Flags;
    const(wchar)* SequenceText;
    size_t InCount;
    FarMacroValue* InValues;
    size_t OutCount;
    const(FarMacroValue)* OutValues;
}

struct FarMacroLoad
{
	size_t StructSize;
	const(wchar)* Path;
	ulong Flags;
}

alias FARSETCOLORFLAGS = ulong;
const FARSETCOLORFLAGS
    FSETCLR_REDRAW                 = 0x0000000000000001UL,
    FSETCLR_NONE                   = 0UL;

struct FarSetColors
{
    size_t StructSize;
    FARSETCOLORFLAGS Flags;
    size_t StartIndex;
    size_t ColorsCount;
    FarColor* Colors;
}

enum WINDOWINFO_TYPE
{
    WTYPE_DESKTOP                   = 0,
    WTYPE_PANELS                    = 1,
    WTYPE_VIEWER                    = 2,
    WTYPE_EDITOR                    = 3,
    WTYPE_DIALOG                    = 4,
    WTYPE_VMENU                     = 5,
    WTYPE_HELP                      = 6,
    WTYPE_COMBOBOX                  = 7,
    WTYPE_GRABBER                   = 8,
    WTYPE_HMENU                     = 9,
}

alias WINDOWINFO_FLAGS = ulong;
const WINDOWINFO_FLAGS
    WIF_MODIFIED = 0x0000000000000001UL,
    WIF_CURRENT  = 0x0000000000000002UL,
    WIF_MODAL    = 0x0000000000000004UL,
    WIF_NONE     = 0;

struct WindowInfo
{
    size_t StructSize;
    intptr_t Id;
    wchar* TypeName;
    wchar* Name;
    intptr_t TypeNameSize;
    intptr_t NameSize;
    intptr_t Pos;
    WINDOWINFO_TYPE Type;
    WINDOWINFO_FLAGS Flags;
}

struct WindowType
{
    size_t StructSize;
    WINDOWINFO_TYPE Type;
}

enum TASKBARPROGRESSTATE
{
    TBPS_NOPROGRESS   =0x0,
    TBPS_INDETERMINATE=0x1,
    TBPS_NORMAL       =0x2,
    TBPS_ERROR        =0x4,
    TBPS_PAUSED       =0x8,
}

struct ProgressValue
{
    size_t StructSize;
    ulong Completed;
    ulong Total;
}

enum VIEWER_CONTROL_COMMANDS
{
    VCTL_GETINFO                    = 0,
    VCTL_QUIT                       = 1,
    VCTL_REDRAW                     = 2,
    VCTL_SETKEYBAR                  = 3,
    VCTL_SETPOSITION                = 4,
    VCTL_SELECT                     = 5,
    VCTL_SETMODE                    = 6,
    VCTL_GETFILENAME                = 7,
}

alias VIEWER_OPTIONS = ulong;
const VIEWER_OPTIONS
    VOPT_SAVEFILEPOSITION   = 0x0000000000000001UL,
    VOPT_AUTODETECTCODEPAGE = 0x0000000000000002UL,
    VOPT_SHOWTITLEBAR       = 0x0000000000000004UL,
    VOPT_SHOWKEYBAR         = 0x0000000000000008UL,
    VOPT_SHOWSCROLLBAR      = 0x0000000000000010UL,
    VOPT_QUICKVIEW          = 0x0000000000000020UL,
    VOPT_NONE               = 0UL;

enum VIEWER_SETMODE_TYPES
{
    VSMT_VIEWMODE                   = 0,
    VSMT_WRAP                       = 1,
    VSMT_WORDWRAP                   = 2,
}

alias VIEWER_SETMODEFLAGS_TYPES = ulong;
const VIEWER_SETMODEFLAGS_TYPES
    VSMFL_REDRAW    = 0x0000000000000001UL,
    VSMFL_NONE      = 0;

struct ViewerSetMode
{
    size_t StructSize;
    VIEWER_SETMODE_TYPES Type;
    union
    {
        intptr_t iParam;
        wchar* wszParam;
    }
    VIEWER_SETMODEFLAGS_TYPES Flags;
}

struct ViewerSelect
{
    size_t StructSize;
    long BlockStartPos;
    long BlockLen;
}

alias VIEWER_SETPOS_FLAGS = ulong;
const VIEWER_SETPOS_FLAGS
    VSP_NOREDRAW    = 0x0000000000000001UL,
    VSP_PERCENT     = 0x0000000000000002UL,
    VSP_RELATIVE    = 0x0000000000000004UL,
    VSP_NORETNEWPOS = 0x0000000000000008UL,
    VSP_NONE        = 0;

struct ViewerSetPosition
{
    size_t StructSize;
    VIEWER_SETPOS_FLAGS Flags;
    long StartPos;
    long LeftPos;
}

alias VIEWER_MODE_FLAGS = ulong;
const VIEWER_MODE_FLAGS
    VMF_WRAP     = 0x0000000000000001UL,
    VMF_WORDWRAP = 0x0000000000000002UL,
    VMF_NONE     = 0;

enum VIEWER_MODE_TYPE
{
    VMT_TEXT    =0,
    VMT_HEX     =1,
    VMT_DUMP    =2,
}

struct ViewerMode
{
    uintptr_t CodePage;
    VIEWER_MODE_FLAGS Flags;
    VIEWER_MODE_TYPE ViewMode;
}

struct ViewerInfo
{
    size_t StructSize;
    intptr_t ViewerID;
    intptr_t TabSize;
    ViewerMode CurMode;
    long FileSize;
    long FilePos;
    long LeftPos;
    VIEWER_OPTIONS Options;
    intptr_t WindowSizeX;
    intptr_t WindowSizeY;
}

enum VIEWER_EVENTS
{
    VE_READ       =0,
    VE_CLOSE      =1,

    VE_GOTFOCUS   =6,
    VE_KILLFOCUS  =7,
}

enum EDITOR_EVENTS
{
    EE_READ       =0,
    EE_SAVE       =1,
    EE_REDRAW     =2,
    EE_CLOSE      =3,

    EE_GOTFOCUS   =6,
    EE_KILLFOCUS  =7,
    EE_CHANGE     =8,
}

enum DIALOG_EVENTS
{
    DE_DLGPROCINIT    =0,
    DE_DEFDLGPROCINIT =1,
    DE_DLGPROCEND     =2,
}

enum SYNCHRO_EVENTS
{
    SE_COMMONSYNCHRO  =0,
}

const EEREDRAW_ALL   = cast(void*)0;
const CURRENT_EDITOR = -1;

enum EDITOR_CONTROL_COMMANDS
{
    ECTL_GETSTRING                  = 0,
    ECTL_SETSTRING                  = 1,
    ECTL_INSERTSTRING               = 2,
    ECTL_DELETESTRING               = 3,
    ECTL_DELETECHAR                 = 4,
    ECTL_INSERTTEXT                 = 5,
    ECTL_GETINFO                    = 6,
    ECTL_SETPOSITION                = 7,
    ECTL_SELECT                     = 8,
    ECTL_REDRAW                     = 9,
    ECTL_TABTOREAL                  = 10,
    ECTL_REALTOTAB                  = 11,
    ECTL_EXPANDTABS                 = 12,
    ECTL_SETTITLE                   = 13,
    ECTL_READINPUT                  = 14,
    ECTL_PROCESSINPUT               = 15,
    ECTL_ADDCOLOR                   = 16,
    ECTL_GETCOLOR                   = 17,
    ECTL_SAVEFILE                   = 18,
    ECTL_QUIT                       = 19,
    ECTL_SETKEYBAR                  = 20,

    ECTL_SETPARAM                   = 22,
    ECTL_GETBOOKMARKS               = 23,
    ECTL_DELETEBLOCK                = 25,
    ECTL_ADDSESSIONBOOKMARK         = 26,
    ECTL_PREVSESSIONBOOKMARK        = 27,
    ECTL_NEXTSESSIONBOOKMARK        = 28,
    ECTL_CLEARSESSIONBOOKMARKS      = 29,
    ECTL_DELETESESSIONBOOKMARK      = 30,
    ECTL_GETSESSIONBOOKMARKS        = 31,
    ECTL_UNDOREDO                   = 32,
    ECTL_GETFILENAME                = 33,
    ECTL_DELCOLOR                   = 34,
    ECTL_SUBSCRIBECHANGEEVENT       = 36,
    ECTL_UNSUBSCRIBECHANGEEVENT     = 37,
    ECTL_GETTITLE                   = 38,
}

enum EDITOR_SETPARAMETER_TYPES
{
    ESPT_TABSIZE                    = 0,
    ESPT_EXPANDTABS                 = 1,
    ESPT_AUTOINDENT                 = 2,
    ESPT_CURSORBEYONDEOL            = 3,
    ESPT_CHARCODEBASE               = 4,
    ESPT_CODEPAGE                   = 5,
    ESPT_SAVEFILEPOSITION           = 6,
    ESPT_LOCKMODE                   = 7,
    ESPT_SETWORDDIV                 = 8,
    ESPT_GETWORDDIV                 = 9,
    ESPT_SHOWWHITESPACE             = 10,
    ESPT_SETBOM                     = 11,
}

struct EditorSetParameter
{
    size_t StructSize;
    EDITOR_SETPARAMETER_TYPES Type;
    union
    {
        intptr_t iParam;
        wchar* wszParam;
        intptr_t Reserved;
    }
    ulong Flags;
    size_t Size;
}

enum EDITOR_UNDOREDO_COMMANDS
{
    EUR_BEGIN                       = 0,
    EUR_END                         = 1,
    EUR_UNDO                        = 2,
    EUR_REDO                        = 3,
}

struct EditorUndoRedo
{
    size_t StructSize;
    EDITOR_UNDOREDO_COMMANDS Command;
}

struct EditorGetString
{
    size_t StructSize;
    intptr_t StringNumber;
    intptr_t StringLength;
    const(wchar)* StringText;
    const(wchar)* StringEOL;
    intptr_t SelStart;
    intptr_t SelEnd;
}

struct EditorSetString
{
    size_t StructSize;
    intptr_t StringNumber;
    intptr_t StringLength;
    const(wchar)* StringText;
    const(wchar)* StringEOL;
}

enum EXPAND_TABS
{
    EXPAND_NOTABS                   = 0,
    EXPAND_ALLTABS                  = 1,
    EXPAND_NEWTABS                  = 2,
}

enum EDITOR_OPTIONS
{
    EOPT_EXPANDALLTABS     = 0x00000001,
    EOPT_PERSISTENTBLOCKS  = 0x00000002,
    EOPT_DELREMOVESBLOCKS  = 0x00000004,
    EOPT_AUTOINDENT        = 0x00000008,
    EOPT_SAVEFILEPOSITION  = 0x00000010,
    EOPT_AUTODETECTCODEPAGE= 0x00000020,
    EOPT_CURSORBEYONDEOL   = 0x00000040,
    EOPT_EXPANDONLYNEWTABS = 0x00000080,
    EOPT_SHOWWHITESPACE    = 0x00000100,
    EOPT_BOM               = 0x00000200,
    EOPT_SHOWLINEBREAK     = 0x00000400,
    EOPT_SHOWTITLEBAR      = 0x00000800,
    EOPT_SHOWKEYBAR        = 0x00001000,
    EOPT_SHOWSCROLLBAR     = 0x00002000,
}

enum EDITOR_BLOCK_TYPES
{
    BTYPE_NONE                      = 0,
    BTYPE_STREAM                    = 1,
    BTYPE_COLUMN                    = 2,
}

enum EDITOR_CURRENTSTATE
{
    ECSTATE_MODIFIED       = 0x00000001,
    ECSTATE_SAVED          = 0x00000002,
    ECSTATE_LOCKED         = 0x00000004,
}

struct EditorInfo
{
    size_t StructSize;
    intptr_t EditorID;
    intptr_t WindowSizeX;
    intptr_t WindowSizeY;
    intptr_t TotalLines;
    intptr_t CurLine;
    intptr_t CurPos;
    intptr_t CurTabPos;
    intptr_t TopScreenLine;
    intptr_t LeftPos;
    intptr_t Overtype;
    intptr_t BlockType;
    intptr_t BlockStartLine;
    uintptr_t Options;
    intptr_t TabSize;
    size_t BookmarkCount;
    size_t SessionBookmarkCount;
    uintptr_t CurState;
    uintptr_t CodePage;
}

struct EditorBookmarks
{
    size_t StructSize;
    size_t Size;
    size_t Count;
    intptr_t* Line;
    intptr_t* Cursor;
    intptr_t* ScreenLine;
    intptr_t* LeftPos;
}

struct EditorSetPosition
{
    size_t StructSize;
    intptr_t CurLine;
    intptr_t CurPos;
    intptr_t CurTabPos;
    intptr_t TopScreenLine;
    intptr_t LeftPos;
    intptr_t Overtype;
}

struct EditorSelect
{
    size_t StructSize;
    intptr_t BlockType;
    intptr_t BlockStartLine;
    intptr_t BlockStartPos;
    intptr_t BlockWidth;
    intptr_t BlockHeight;
}

struct EditorConvertPos
{
    size_t StructSize;
    intptr_t StringNumber;
    intptr_t SrcPos;
    intptr_t DestPos;
}


alias EDITORCOLORFLAGS = ulong;
const EDITORCOLORFLAGS
    ECF_TABMARKFIRST   = 0x0000000000000001UL,
    ECF_TABMARKCURRENT = 0x0000000000000002UL,
    ECF_AUTODELETE     = 0x0000000000000004UL,
    ECF_NONE           = 0;

struct EditorColor
{
    size_t StructSize;
    intptr_t StringNumber;
    intptr_t ColorItem;
    intptr_t StartPos;
    intptr_t EndPos;
    uintptr_t Priority;
    EDITORCOLORFLAGS Flags;
    FarColor Color;
    GUID Owner;
}

struct EditorDeleteColor
{
    size_t StructSize;
    GUID Owner;
    intptr_t StringNumber;
    intptr_t StartPos;
}

const EDITOR_COLOR_NORMAL_PRIORITY = 0x80000000U;

struct EditorSaveFile
{
    size_t StructSize;
    const(wchar)* FileName;
    const(wchar)* FileEOL;
    uintptr_t CodePage;
}

enum EDITOR_CHANGETYPE
{
    ECTYPE_CHANGED = 0,
    ECTYPE_ADDED   = 1,
    ECTYPE_DELETED = 2,
}

struct EditorChange
{
    size_t StructSize;
    EDITOR_CHANGETYPE Type;
    intptr_t StringNumber;
}

struct EditorSubscribeChangeEvent
{
    size_t StructSize;
    GUID PluginId;
}

alias INPUTBOXFLAGS = ulong;
const INPUTBOXFLAGS
    FIB_ENABLEEMPTY      = 0x0000000000000001UL,
    FIB_PASSWORD         = 0x0000000000000002UL,
    FIB_EXPANDENV        = 0x0000000000000004UL,
    FIB_NOUSELASTHISTORY = 0x0000000000000008UL,
    FIB_BUTTONS          = 0x0000000000000010UL,
    FIB_NOAMPERSAND      = 0x0000000000000020UL,
    FIB_EDITPATH         = 0x0000000000000040UL,
    FIB_EDITPATHEXEC     = 0x0000000000000080UL,
    FIB_NONE             = 0UL;

alias FARAPIINPUTBOX = extern (Windows) intptr_t function(
    in GUID* PluginId,
    in GUID* Id,
    in wchar* Title,
    in wchar* SubTitle,
    in wchar* HistoryName,
    in wchar* SrcText,
    wchar* DestText,
    size_t DestSize,
    in wchar* HelpTopic,
    INPUTBOXFLAGS Flags);

enum FAR_PLUGINS_CONTROL_COMMANDS
{
    PCTL_LOADPLUGIN           = 0,
    PCTL_UNLOADPLUGIN         = 1,
    PCTL_FORCEDLOADPLUGIN     = 2,
    PCTL_FINDPLUGIN           = 3,
    PCTL_GETPLUGININFORMATION = 4,
    PCTL_GETPLUGINS           = 5,
}

enum FAR_PLUGIN_LOAD_TYPE
{
    PLT_PATH = 0,
}

enum FAR_PLUGIN_FIND_TYPE
{
    PFM_GUID       = 0,
    PFM_MODULENAME = 1,
}

alias FAR_PLUGIN_FLAGS = ulong;
const FAR_PLUGIN_FLAGS
    FPF_LOADED         = 0x0000000000000001UL,
    FPF_ANSI           = 0x1000000000000000UL,
    FPF_NONE           = 0UL;

enum FAR_FILE_FILTER_CONTROL_COMMANDS
{
    FFCTL_CREATEFILEFILTER          = 0,
    FFCTL_FREEFILEFILTER            = 1,
    FFCTL_OPENFILTERSMENU           = 2,
    FFCTL_STARTINGTOFILTER          = 3,
    FFCTL_ISFILEINFILTER            = 4,
}

enum FAR_FILE_FILTER_TYPE
{
    FFT_PANEL                       = 0,
    FFT_FINDFILE                    = 1,
    FFT_COPY                        = 2,
    FFT_SELECT                      = 3,
    FFT_CUSTOM                      = 4,
}

enum FAR_REGEXP_CONTROL_COMMANDS
{
    RECTL_CREATE                    = 0,
    RECTL_FREE                      = 1,
    RECTL_COMPILE                   = 2,
    RECTL_OPTIMIZE                  = 3,
    RECTL_MATCHEX                   = 4,
    RECTL_SEARCHEX                  = 5,
    RECTL_BRACKETSCOUNT             = 6,
}

struct RegExpMatch
{
    intptr_t start,end;
}

struct RegExpSearch
{
    const(wchar)* Text;
    intptr_t Position;
    intptr_t Length;
    RegExpMatch* Match;
    intptr_t Count;
    void* Reserved;
}

enum FAR_SETTINGS_CONTROL_COMMANDS
{
    SCTL_CREATE                     = 0,
    SCTL_FREE                       = 1,
    SCTL_SET                        = 2,
    SCTL_GET                        = 3,
    SCTL_ENUM                       = 4,
    SCTL_DELETE                     = 5,
    SCTL_CREATESUBKEY               = 6,
    SCTL_OPENSUBKEY                 = 7,
}

enum FARSETTINGSTYPES
{
    FST_UNKNOWN                     = 0,
    FST_SUBKEY                      = 1,
    FST_QWORD                       = 2,
    FST_STRING                      = 3,
    FST_DATA                        = 4,
}

enum FARSETTINGS_SUBFOLDERS
{
    FSSF_ROOT                       =  0,
    FSSF_HISTORY_CMD                =  1,
    FSSF_HISTORY_FOLDER             =  2,
    FSSF_HISTORY_VIEW               =  3,
    FSSF_HISTORY_EDIT               =  4,
    FSSF_HISTORY_EXTERNAL           =  5,
    FSSF_FOLDERSHORTCUT_0           =  6,
    FSSF_FOLDERSHORTCUT_1           =  7,
    FSSF_FOLDERSHORTCUT_2           =  8,
    FSSF_FOLDERSHORTCUT_3           =  9,
    FSSF_FOLDERSHORTCUT_4           = 10,
    FSSF_FOLDERSHORTCUT_5           = 11,
    FSSF_FOLDERSHORTCUT_6           = 12,
    FSSF_FOLDERSHORTCUT_7           = 13,
    FSSF_FOLDERSHORTCUT_8           = 14,
    FSSF_FOLDERSHORTCUT_9           = 15,
    FSSF_CONFIRMATIONS              = 16,
    FSSF_SYSTEM                     = 17,
    FSSF_PANEL                      = 18,
    FSSF_EDITOR                     = 19,
    FSSF_SCREEN                     = 20,
    FSSF_DIALOG                     = 21,
    FSSF_INTERFACE                  = 22,
    FSSF_PANELLAYOUT                = 23,
}

enum FAR_PLUGIN_SETTINGS_LOCATION
{
    PSL_ROAMING = 0,
    PSL_LOCAL   = 1,
}

struct FarSettingsCreate
{
    size_t StructSize;
    GUID Guid;
    HANDLE Handle;
}

struct FarSettingsItemData
{
    size_t Size;
    const(void)* Data;
}

struct FarSettingsItem
{
    size_t StructSize;
    size_t Root;
    const(wchar)* Name;
    FARSETTINGSTYPES Type;
    union
    {
        ulong Number;
        const(wchar)* String;
        FarSettingsItemData Data;
    }
}

struct FarSettingsName
{
    const(wchar)* Name;
    FARSETTINGSTYPES Type;
}

struct FarSettingsHistory
{
    const(wchar)* Name;
    const(wchar)* Param;
    GUID PluginId;
    const(wchar)* File;
    FILETIME Time;
    BOOL Lock;
}

struct FarSettingsEnum
{
    size_t StructSize;
    size_t Root;
    size_t Count;
    union
    {
        const(FarSettingsName)* Items;
        const(FarSettingsHistory)* Histories;
    }
}

struct FarSettingsValue
{
    size_t StructSize;
    size_t Root;
    const(wchar)* Value;
}

alias FARAPIPANELCONTROL = extern (Windows) intptr_t function(HANDLE hPanel, FILE_CONTROL_COMMANDS Command, intptr_t Param1, void* Param2);

alias FARAPIADVCONTROL = extern (Windows) intptr_t function(
    in GUID* PluginId,
    ADVANCED_CONTROL_COMMANDS Command,
    intptr_t Param1,
    void* Param2);

alias FARAPIVIEWERCONTROL = extern (Windows) intptr_t function(intptr_t ViewerID, VIEWER_CONTROL_COMMANDS Command, intptr_t Param1, void* Param2);

alias FARAPIEDITORCONTROL = extern (Windows) intptr_t function(intptr_t EditorID, EDITOR_CONTROL_COMMANDS Command, intptr_t Param1, void* Param2);

alias FARAPIMACROCONTROL = extern (Windows) intptr_t function(
    in GUID* PluginId,
    FAR_MACRO_CONTROL_COMMANDS Command,
    intptr_t Param1,
    void* Param2);

alias FARAPIPLUGINSCONTROL = extern (Windows) intptr_t function(HANDLE hHandle, FAR_PLUGINS_CONTROL_COMMANDS Command, intptr_t Param1, void* Param2);

alias FARAPIFILEFILTERCONTROL = extern (Windows) intptr_t function(HANDLE hHandle, FAR_FILE_FILTER_CONTROL_COMMANDS Command, intptr_t Param1, void* Param2);

alias FARAPIREGEXPCONTROL = extern (Windows) intptr_t function(HANDLE hHandle, FAR_REGEXP_CONTROL_COMMANDS Command, intptr_t Param1, void* Param2);

alias FARAPISETTINGSCONTROL = extern (Windows) intptr_t function(HANDLE hHandle, FAR_SETTINGS_CONTROL_COMMANDS Command, intptr_t Param1, void* Param2);

enum FARCLIPBOARD_TYPE
{
    FCT_ANY=0,
    FCT_STREAM=1,
    FCT_COLUMN=2
}

alias FARSTDSPRINTF = extern (C) int function(wchar* Buffer, in wchar* Format, ...);

alias FARSTDSNPRINTF = extern (C) int function(wchar* Buffer, size_t Sizebuf, in wchar* Format, ...);

alias FARSTDSSCANF = extern (C) int function(in wchar* Buffer, in wchar* Format, ...);

alias FARSTDQSORT = extern (Windows) void function(void* base, size_t nelem, size_t width, int function(in void* , in void* , void* userparam)fcmp, void* userparam);

alias FARSTDBSEARCH = extern (Windows) void* function(in void* key, in void* base, size_t nelem, size_t width, int function(in void* , in void* , void* userparam)fcmp, void* userparam);

alias FARSTDGETFILEOWNER = extern (Windows) size_t function(in wchar* Computer, in wchar* Name, wchar* Owner, size_t Size);

alias FARSTDGETNUMBEROFLINKS = extern (Windows) size_t function(in wchar* Name);

alias FARSTDATOI = extern (Windows) int function(in wchar* s);

alias FARSTDATOI64 = extern (Windows) long function(in wchar* s);

alias FARSTDITOA64 = extern (Windows) wchar* function(long value, wchar* Str, int radix);

alias FARSTDITOA = extern (Windows) wchar* function(int value, wchar* Str, int radix);

alias FARSTDLTRIM = extern (Windows) wchar* function(wchar* Str);

alias FARSTDRTRIM = extern (Windows) wchar* function(wchar* Str);

alias FARSTDTRIM = extern (Windows) wchar* function(wchar* Str);

alias FARSTDTRUNCSTR = extern (Windows) wchar* function(wchar* Str, intptr_t MaxLength);

alias FARSTDTRUNCPATHSTR = extern (Windows) wchar* function(wchar* Str, intptr_t MaxLength);

alias FARSTDQUOTESPACEONLY = extern (Windows) wchar* function(wchar* Str);

alias FARSTDPOINTTONAME = extern (Windows) const(wchar)* function(in wchar* Path);

alias FARSTDADDENDSLASH = extern (Windows) BOOL function(wchar* Path);

alias FARSTDCOPYTOCLIPBOARD = extern (Windows) BOOL function(FARCLIPBOARD_TYPE Type, in wchar* Data);

alias FARSTDPASTEFROMCLIPBOARD = extern (Windows) size_t function(FARCLIPBOARD_TYPE Type, wchar* Data, size_t Size);

alias FARSTDLOCALISLOWER = extern (Windows) int function(wchar Ch);

alias FARSTDLOCALISUPPER = extern (Windows) int function(wchar Ch);

alias FARSTDLOCALISALPHA = extern (Windows) int function(wchar Ch);

alias FARSTDLOCALISALPHANUM = extern (Windows) int function(wchar Ch);

alias FARSTDLOCALUPPER = extern (Windows) wchar function(wchar LowerChar);

alias FARSTDLOCALLOWER = extern (Windows) wchar function(wchar UpperChar);

alias FARSTDLOCALUPPERBUF = extern (Windows) void function(wchar* Buf, intptr_t Length);

alias FARSTDLOCALLOWERBUF = extern (Windows) void function(wchar* Buf, intptr_t Length);

alias FARSTDLOCALSTRUPR = extern (Windows) void function(wchar* s1);

alias FARSTDLOCALSTRLWR = extern (Windows) void function(wchar* s1);

deprecated
alias FARSTDLOCALSTRICMP = extern (Windows) int function(in wchar* s1, in wchar* s2);

deprecated
alias FARSTDLOCALSTRNICMP = extern (Windows) int function(in wchar* s1, in wchar* s2, intptr_t n);

alias FARSTDFARCLOCK = extern (Windows) ulong function();

alias FARSTDCOMPARESTRINGS = extern (Windows) int function(in wchar* Str1, size_t Size1, in wchar* Str2, size_t Size2);

alias PROCESSNAME_FLAGS = ulong;
const PROCESSNAME_FLAGS
    //             0xFFFF - length
    //           0xFF0000 - mode
    // 0xFFFFFFFFFF000000 - flags
    PN_CMPNAME          = 0x0000000000000000UL,
    PN_CMPNAMELIST      = 0x0000000000010000UL,
    PN_GENERATENAME     = 0x0000000000020000UL,
    PN_CHECKMASK        = 0x0000000000030000UL,
    PN_SKIPPATH         = 0x0000000001000000UL,
    PN_SHOWERRORMESSAGE = 0x0000000002000000UL,
    PN_NONE             = 0;

alias FARSTDPROCESSNAME = extern (Windows) size_t function(
    in wchar* param1,
    wchar* param2,
    size_t size,
    PROCESSNAME_FLAGS flags);

alias FARSTDUNQUOTE = extern (Windows) void function(wchar* Str);

alias XLAT_FLAGS = ulong;
const XLAT_FLAGS
    XLAT_SWITCHKEYBLAYOUT  = 0x0000000000000001UL,
    XLAT_SWITCHKEYBBEEP    = 0x0000000000000002UL,
    XLAT_USEKEYBLAYOUTNAME = 0x0000000000000004UL,
    XLAT_CONVERTALLCMDLINE = 0x0000000000010000UL,
    XLAT_NONE              = 0UL;

alias FARSTDINPUTRECORDTOKEYNAME = extern (Windows) size_t function(
    in INPUT_RECORD* Key,
    wchar* KeyText,
    size_t Size);

alias FARSTDXLAT = extern (Windows) wchar* function(wchar* Line, intptr_t StartPos, intptr_t EndPos, XLAT_FLAGS Flags);

alias FARSTDKEYNAMETOINPUTRECORD = extern (Windows) BOOL function(
    in wchar* Name,
    INPUT_RECORD* Key);

alias FRSUSERFUNC = extern (Windows) int function(
    in PluginPanelItem* FData,
    in wchar* FullName,
    void* Param);

alias FRSMODE = ulong;
const FRSMODE
    FRS_RETUPDIR             = 0x0000000000000001UL,
    FRS_RECUR                = 0x0000000000000002UL,
    FRS_SCANSYMLINK          = 0x0000000000000004UL,
    FRS_NONE                 = 0;

alias FARSTDRECURSIVESEARCH = extern (Windows) void function(
    in wchar* InitDir,
    in wchar* Mask,
    FRSUSERFUNC Func,
    FRSMODE Flags,
    void* Param);

alias FARSTDMKTEMP = extern (Windows) size_t function(
    wchar* Dest,
    size_t DestSize,
    in wchar* Prefix);

alias FARSTDGETPATHROOT = extern (Windows) size_t function(
    in wchar* Path,
    wchar* Root,
    size_t DestSize);

enum LINK_TYPE
{
    LINK_HARDLINK         = 1,
    LINK_JUNCTION         = 2,
    LINK_VOLMOUNT         = 3,
    LINK_SYMLINKFILE      = 4,
    LINK_SYMLINKDIR       = 5,
    LINK_SYMLINK          = 6,
}

alias MKLINK_FLAGS = ulong;
const MKLINK_FLAGS
    MLF_SHOWERRMSG       = 0x0000000000010000UL,
    MLF_DONOTUPDATEPANEL = 0x0000000000020000UL,
    MLF_HOLDTARGET       = 0x0000000000040000UL,
    MLF_NONE             = 0UL;

alias FARSTDMKLINK = extern (Windows) BOOL function(
    in wchar* Src,
    in wchar* Dest,
    LINK_TYPE Type,
    MKLINK_FLAGS Flags);

alias FARGETREPARSEPOINTINFO = extern (Windows) size_t function(
    in wchar* Src,
    wchar* Dest,
    size_t DestSize);

enum CONVERTPATHMODES
{
    CPM_FULL                        = 0,
    CPM_REAL                        = 1,
    CPM_NATIVE                      = 2,
}

alias FARCONVERTPATH = extern (Windows) size_t function(
    CONVERTPATHMODES Mode,
    in wchar* Src,
    wchar* Dest,
    size_t DestSize);

alias FARGETCURRENTDIRECTORY = extern (Windows) size_t function(size_t Size, wchar* Buffer);

alias FARFORMATFILESIZEFLAGS = ulong;
const FARFORMATFILESIZEFLAGS
    FFFS_COMMAS                 = 0x0100000000000000UL,
    FFFS_FLOATSIZE              = 0x0200000000000000UL,
    FFFS_SHOWBYTESINDEX         = 0x0400000000000000UL,
    FFFS_ECONOMIC               = 0x0800000000000000UL,
    FFFS_THOUSAND               = 0x1000000000000000UL,
    FFFS_MINSIZEINDEX           = 0x2000000000000000UL,
    FFFS_MINSIZEINDEX_MASK      = 0x0000000000000003UL,
    FFFS_NONE                   = 0;

alias FARFORMATFILESIZE = extern (Windows) size_t function(ulong Size, intptr_t Width, FARFORMATFILESIZEFLAGS Flags, wchar* Dest, size_t DestSize);

struct FarStandardFunctions
{
    size_t StructSize;
    FARSTDATOI atoi;
    FARSTDATOI64 atoi64;
    FARSTDITOA itoa;
    FARSTDITOA64 itoa64;
    FARSTDSPRINTF sprintf;
    FARSTDSSCANF sscanf;
    FARSTDQSORT qsort;
    FARSTDBSEARCH bsearch;
    FARSTDSNPRINTF snprintf;
    FARSTDLOCALISLOWER LIsLower;
    FARSTDLOCALISUPPER LIsUpper;
    FARSTDLOCALISALPHA LIsAlpha;
    FARSTDLOCALISALPHANUM LIsAlphanum;
    FARSTDLOCALUPPER LUpper;
    FARSTDLOCALLOWER LLower;
    FARSTDLOCALUPPERBUF LUpperBuf;
    FARSTDLOCALLOWERBUF LLowerBuf;
    FARSTDLOCALSTRUPR LStrupr;
    FARSTDLOCALSTRLWR LStrlwr;
    deprecated FARSTDLOCALSTRICMP LStricmp;
    deprecated FARSTDLOCALSTRNICMP LStrnicmp;
    FARSTDUNQUOTE Unquote;
    FARSTDLTRIM LTrim;
    FARSTDRTRIM RTrim;
    FARSTDTRIM Trim;
    FARSTDTRUNCSTR TruncStr;
    FARSTDTRUNCPATHSTR TruncPathStr;
    FARSTDQUOTESPACEONLY QuoteSpaceOnly;
    FARSTDPOINTTONAME PointToName;
    FARSTDGETPATHROOT GetPathRoot;
    FARSTDADDENDSLASH AddEndSlash;
    FARSTDCOPYTOCLIPBOARD CopyToClipboard;
    FARSTDPASTEFROMCLIPBOARD PasteFromClipboard;
    FARSTDINPUTRECORDTOKEYNAME FarInputRecordToName;
    FARSTDKEYNAMETOINPUTRECORD FarNameToInputRecord;
    FARSTDXLAT XLat;
    FARSTDGETFILEOWNER GetFileOwner;
    FARSTDGETNUMBEROFLINKS GetNumberOfLinks;
    FARSTDRECURSIVESEARCH FarRecursiveSearch;
    FARSTDMKTEMP MkTemp;
    FARSTDPROCESSNAME ProcessName;
    FARSTDMKLINK MkLink;
    FARCONVERTPATH ConvertPath;
    FARGETREPARSEPOINTINFO GetReparsePointInfo;
    FARGETCURRENTDIRECTORY GetCurrentDirectory;
    FARFORMATFILESIZE FormatFileSize;
    FARSTDFARCLOCK FarClock;
    FARSTDCOMPARESTRINGS CompareStrings;
}
alias FARSTANDARDFUNCTIONS = FarStandardFunctions;

struct PluginStartupInfo
{
    size_t StructSize;
    const(wchar)* ModuleName;
    FARAPIMENU Menu;
    FARAPIMESSAGE Message;
    FARAPIGETMSG GetMsg;
    FARAPIPANELCONTROL PanelControl;
    FARAPISAVESCREEN SaveScreen;
    FARAPIRESTORESCREEN RestoreScreen;
    FARAPIGETDIRLIST GetDirList;
    FARAPIGETPLUGINDIRLIST GetPluginDirList;
    FARAPIFREEDIRLIST FreeDirList;
    FARAPIFREEPLUGINDIRLIST FreePluginDirList;
    FARAPIVIEWER Viewer;
    FARAPIEDITOR Editor;
    FARAPITEXT Text;
    FARAPIEDITORCONTROL EditorControl;
    FARSTANDARDFUNCTIONS* FSF;
    FARAPISHOWHELP ShowHelp;
    FARAPIADVCONTROL AdvControl;
    FARAPIINPUTBOX InputBox;
    FARAPICOLORDIALOG ColorDialog;
    FARAPIDIALOGINIT DialogInit;
    FARAPIDIALOGRUN DialogRun;
    FARAPIDIALOGFREE DialogFree;
    FARAPISENDDLGMESSAGE SendDlgMessage;
    FARAPIDEFDLGPROC DefDlgProc;
    FARAPIVIEWERCONTROL ViewerControl;
    FARAPIPLUGINSCONTROL PluginsControl;
    FARAPIFILEFILTERCONTROL FileFilterControl;
    FARAPIREGEXPCONTROL RegExpControl;
    FARAPIMACROCONTROL MacroControl;
    FARAPISETTINGSCONTROL SettingsControl;
    void* Private;
    void* Instance;
}

alias FARAPICREATEFILE = extern (Windows) HANDLE function(
    in wchar* Object,
    DWORD DesiredAccess,
    DWORD ShareMode,
    LPSECURITY_ATTRIBUTES SecurityAttributes,
    DWORD CreationDistribution,
    DWORD FlagsAndAttributes,
    HANDLE TemplateFile);

alias FARAPIGETFILEATTRIBUTES = extern (Windows) DWORD function(in wchar* FileName);

alias FARAPISETFILEATTRIBUTES = extern (Windows) BOOL function(
    in wchar* FileName,
    DWORD dwFileAttributes);

alias FARAPIMOVEFILEEX = extern (Windows) BOOL function(
    in wchar* ExistingFileName,
    in wchar* NewFileName,
    DWORD dwFlags);

alias FARAPIDELETEFILE = extern (Windows) BOOL function(in wchar* FileName);

alias FARAPIREMOVEDIRECTORY = extern (Windows) BOOL function(in wchar* DirName);

alias FARAPICREATEDIRECTORY = extern (Windows) BOOL function(
    in wchar* PathName,
    LPSECURITY_ATTRIBUTES lpSecurityAttributes);

struct ArclitePrivateInfo
{
    size_t StructSize;
    FARAPICREATEFILE CreateFile;
    FARAPIGETFILEATTRIBUTES GetFileAttributes;
    FARAPISETFILEATTRIBUTES SetFileAttributes;
    FARAPIMOVEFILEEX MoveFileEx;
    FARAPIDELETEFILE DeleteFile;
    FARAPIREMOVEDIRECTORY RemoveDirectory;
    FARAPICREATEDIRECTORY CreateDirectory;
}

struct NetBoxPrivateInfo
{
    size_t StructSize;
    FARAPICREATEFILE CreateFile;
    FARAPIGETFILEATTRIBUTES GetFileAttributes;
    FARAPISETFILEATTRIBUTES SetFileAttributes;
    FARAPIMOVEFILEEX MoveFileEx;
    FARAPIDELETEFILE DeleteFile;
    FARAPIREMOVEDIRECTORY RemoveDirectory;
    FARAPICREATEDIRECTORY CreateDirectory;
}

struct MacroPluginReturn
{
    intptr_t ReturnType;
    size_t Count;
    FarMacroValue* Values;
}

alias FARAPICALLFAR = extern (Windows) intptr_t function(intptr_t CheckCode, FarMacroCall* Data);

struct MacroPrivateInfo
{
    size_t StructSize;
    FARAPICALLFAR CallFar;
}

alias PLUGIN_FLAGS = ulong;
const PLUGIN_FLAGS
    PF_PRELOAD        = 0x0000000000000001UL,
    PF_DISABLEPANELS  = 0x0000000000000002UL,
    PF_EDITOR         = 0x0000000000000004UL,
    PF_VIEWER         = 0x0000000000000008UL,
    PF_FULLCMDLINE    = 0x0000000000000010UL,
    PF_DIALOG         = 0x0000000000000020UL,
    PF_NONE           = 0UL;

struct PluginMenuItem
{
    const(GUID)* Guids;
    const(wchar*)* Strings;
    size_t Count;
}

enum VERSION_STAGE
{
    VS_RELEASE                      = 0,
    VS_ALPHA                        = 1,
    VS_BETA                         = 2,
    VS_RC                           = 3,
}

struct VersionInfo
{
    DWORD Major;
    DWORD Minor;
    DWORD Revision;
    DWORD Build;
    VERSION_STAGE Stage;
}

BOOL CheckVersion(in VersionInfo* Current, in VersionInfo* Required)
{
    return (Current.Major > Required.Major) || (Current.Major == Required.Major && Current.Minor > Required.Minor) || (Current.Major == Required.Major && Current.Minor == Required.Minor && Current.Revision > Required.Revision) || (Current.Major == Required.Major && Current.Minor == Required.Minor && Current.Revision == Required.Revision && Current.Build >= Required.Build);
}

VersionInfo MakeFarVersion(DWORD Major, DWORD Minor, DWORD Revision, DWORD Build, VERSION_STAGE Stage)
{
    return VersionInfo(Major, Minor, Revision, Build, Stage);
}
auto FARMANAGERVERSION() { return MakeFarVersion(FARMANAGERVERSION_MAJOR, FARMANAGERVERSION_MINOR, FARMANAGERVERSION_REVISION, FARMANAGERVERSION_BUILD, FARMANAGERVERSION_STAGE); }

struct GlobalInfo
{
    size_t StructSize;
    VersionInfo MinFarVersion;
    VersionInfo Version;
    GUID Guid;
    const(wchar)* Title;
    const(wchar)* Description;
    const(wchar)* Author;
    void* Instance;
}

struct PluginInfo
{
    size_t StructSize;
    PLUGIN_FLAGS Flags;
    PluginMenuItem DiskMenu;
    PluginMenuItem PluginMenu;
    PluginMenuItem PluginConfig;
    const(wchar)* CommandPrefix;
    void* Instance;
}

struct FarGetPluginInformation
{
    size_t StructSize;
    const(wchar)* ModuleName;
    FAR_PLUGIN_FLAGS Flags;
    PluginInfo* PInfo;
    GlobalInfo* GInfo;
}

alias INFOPANELLINE_FLAGS = ulong;
const INFOPANELLINE_FLAGS
    IPLFLAGS_SEPARATOR      = 0x0000000000000001UL,
    IPLFLAGS_NONE           = 0;

struct InfoPanelLine
{
    const(wchar)* Text;
    const(wchar)* Data;
    INFOPANELLINE_FLAGS Flags;
}

alias PANELMODE_FLAGS = ulong;
const PANELMODE_FLAGS
    PMFLAGS_FULLSCREEN      = 0x0000000000000001UL,
    PMFLAGS_DETAILEDSTATUS  = 0x0000000000000002UL,
    PMFLAGS_ALIGNEXTENSIONS = 0x0000000000000004UL,
    PMFLAGS_CASECONVERSION  = 0x0000000000000008UL,
    PMFLAGS_NONE            = 0;

struct PanelMode
{
    const(wchar)* ColumnTypes;
    const(wchar)* ColumnWidths;
    const(wchar*)* ColumnTitles;
    const(wchar)* StatusColumnTypes;
    const(wchar)* StatusColumnWidths;
    PANELMODE_FLAGS Flags;
}

alias OPENPANELINFO_FLAGS = ulong;
const OPENPANELINFO_FLAGS
    OPIF_DISABLEFILTER           = 0x0000000000000001UL,
    OPIF_DISABLESORTGROUPS       = 0x0000000000000002UL,
    OPIF_DISABLEHIGHLIGHTING     = 0x0000000000000004UL,
    OPIF_ADDDOTS                 = 0x0000000000000008UL,
    OPIF_RAWSELECTION            = 0x0000000000000010UL,
    OPIF_REALNAMES               = 0x0000000000000020UL,
    OPIF_SHOWNAMESONLY           = 0x0000000000000040UL,
    OPIF_SHOWRIGHTALIGNNAMES     = 0x0000000000000080UL,
    OPIF_SHOWPRESERVECASE        = 0x0000000000000100UL,
    OPIF_COMPAREFATTIME          = 0x0000000000000400UL,
    OPIF_EXTERNALGET             = 0x0000000000000800UL,
    OPIF_EXTERNALPUT             = 0x0000000000001000UL,
    OPIF_EXTERNALDELETE          = 0x0000000000002000UL,
    OPIF_EXTERNALMKDIR           = 0x0000000000004000UL,
    OPIF_USEATTRHIGHLIGHTING     = 0x0000000000008000UL,
    OPIF_USECRC32                = 0x0000000000010000UL,
    OPIF_USEFREESIZE             = 0x0000000000020000UL,
    OPIF_SHORTCUT                = 0x0000000000040000UL,
    OPIF_NONE                    = 0UL;

struct KeyBarLabel
{
    FarKey Key;
    const(wchar)* Text;
    const(wchar)* LongText;
}

struct KeyBarTitles
{
    size_t CountLabels;
    KeyBarLabel* Labels;
}

struct FarSetKeyBarTitles
{
    size_t StructSize;
    KeyBarTitles* Titles;
}

alias OPERATION_MODES = ulong;
const OPERATION_MODES
    OPM_SILENT     =0x0000000000000001UL,
    OPM_FIND       =0x0000000000000002UL,
    OPM_VIEW       =0x0000000000000004UL,
    OPM_EDIT       =0x0000000000000008UL,
    OPM_TOPLEVEL   =0x0000000000000010UL,
    OPM_DESCR      =0x0000000000000020UL,
    OPM_QUICKVIEW  =0x0000000000000040UL,
    OPM_PGDN       =0x0000000000000080UL,
    OPM_COMMANDS   =0x0000000000000100UL,
    OPM_NONE       =0UL;

struct OpenPanelInfo
{
    size_t StructSize;
    HANDLE hPanel;
    OPENPANELINFO_FLAGS Flags;
    const(wchar)* HostFile;
    const(wchar)* CurDir;
    const(wchar)* Format;
    const(wchar)* PanelTitle;
    const(InfoPanelLine)* InfoLines;
    size_t InfoLinesNumber;
    const(wchar*)* DescrFiles;
    size_t DescrFilesNumber;
    const(PanelMode)* PanelModesArray;
    size_t PanelModesNumber;
    intptr_t StartPanelMode;
    OPENPANELINFO_SORTMODES StartSortMode;
    intptr_t StartSortOrder;
    const(KeyBarTitles)* KeyBar;
    const(wchar)* ShortcutData;
    ulong FreeSize;
    UserDataItem UserData;
    void* Instance;
}

struct AnalyseInfo
{
    size_t StructSize;
    const(wchar)* FileName;
    void* Buffer;
    size_t BufferSize;
    OPERATION_MODES OpMode;
	void* Instance;
}

struct OpenAnalyseInfo
{
    size_t StructSize;
    AnalyseInfo* Info;
    HANDLE Handle;
}

struct OpenMacroInfo
{
    size_t StructSize;
    size_t Count;
    FarMacroValue* Values;
}

alias FAROPENSHORTCUTFLAGS = ulong;
const FAROPENSHORTCUTFLAGS
    FOSF_ACTIVE = 0x0000000000000001UL,
    FOSF_NONE   = 0;

struct OpenShortcutInfo
{
    size_t StructSize;
    const(wchar)* HostFile;
    const(wchar)* ShortcutData;
    FAROPENSHORTCUTFLAGS Flags;
}

struct OpenCommandLineInfo
{
    size_t StructSize;
    const(wchar)* CommandLine;
}

enum OPENFROM
{
    OPEN_LEFTDISKMENU       = 0,
    OPEN_PLUGINSMENU        = 1,
    OPEN_FINDLIST           = 2,
    OPEN_SHORTCUT           = 3,
    OPEN_COMMANDLINE        = 4,
    OPEN_EDITOR             = 5,
    OPEN_VIEWER             = 6,
    OPEN_FILEPANEL          = 7,
    OPEN_DIALOG             = 8,
    OPEN_ANALYSE            = 9,
    OPEN_RIGHTDISKMENU      = 10,
    OPEN_FROMMACRO          = 11,
    OPEN_LUAMACRO           = 100,
}

enum MACROCALLTYPE
{
    MCT_MACROPARSE         = 0,
    MCT_LOADMACROS         = 1,
    MCT_ENUMMACROS         = 2,
    MCT_WRITEMACROS        = 3,
    MCT_GETMACRO           = 4,
    MCT_RECORDEDMACRO      = 5,
    MCT_DELMACRO           = 6,
    MCT_RUNSTARTMACRO      = 7,
    MCT_EXECSTRING         = 8,
    MCT_PANELSORT          = 9,
    MCT_GETCUSTOMSORTMODES = 10,
    MCT_ADDMACRO           = 11,
    MCT_KEYMACRO           = 12,
    MCT_CANPANELSORT       = 13,
}

enum MACROPLUGINRETURNTYPE
{
    MPRT_NORMALFINISH  = 0,
    MPRT_ERRORFINISH   = 1,
    MPRT_ERRORPARSE    = 2,
    MPRT_KEYS          = 3,
    MPRT_PRINT         = 4,
    MPRT_PLUGINCALL    = 5,
    MPRT_PLUGINMENU    = 6,
    MPRT_PLUGINCONFIG  = 7,
    MPRT_PLUGINCOMMAND = 8,
    MPRT_USERMENU      = 9,
    MPRT_HASNOMACRO    = 10,
}

struct OpenMacroPluginInfo
{
    MACROCALLTYPE CallType;
    FarMacroCall* Data;
	MacroPluginReturn Ret;
}

enum FAR_EVENTS
{
    FE_CHANGEVIEWMODE   =0,
    FE_REDRAW           =1,
    FE_IDLE             =2,
    FE_CLOSE            =3,
    FE_BREAK            =4,
    FE_COMMAND          =5,

    FE_GOTFOCUS         =6,
    FE_KILLFOCUS        =7,
    FE_CHANGESORTPARAMS =8,
}

struct OpenInfo
{
    size_t StructSize;
    OPENFROM OpenFrom;
    const(GUID)* Guid;
    intptr_t Data;
	void* Instance;
}

struct SetDirectoryInfo
{
    size_t StructSize;
    HANDLE hPanel;
    const(wchar)* Dir;
    intptr_t Reserved;
    OPERATION_MODES OpMode;
    UserDataItem UserData;
	void* Instance;
}

struct SetFindListInfo
{
    size_t StructSize;
    HANDLE hPanel;
    const(PluginPanelItem)* PanelItem;
    size_t ItemsNumber;
	void* Instance;
}

struct PutFilesInfo
{
    size_t StructSize;
    HANDLE hPanel;
    PluginPanelItem* PanelItem;
    size_t ItemsNumber;
    BOOL Move;
    const(wchar)* SrcPath;
    OPERATION_MODES OpMode;
	void* Instance;
}

struct ProcessHostFileInfo
{
    size_t StructSize;
    HANDLE hPanel;
    PluginPanelItem* PanelItem;
    size_t ItemsNumber;
    OPERATION_MODES OpMode;
	void* Instance;
}

struct MakeDirectoryInfo
{
    size_t StructSize;
    HANDLE hPanel;
    const(wchar)* Name;
    OPERATION_MODES OpMode;
	void* Instance;
}

struct CompareInfo
{
    size_t StructSize;
    HANDLE hPanel;
    const(PluginPanelItem)* Item1;
    const(PluginPanelItem)* Item2;
    OPENPANELINFO_SORTMODES Mode;
	void* Instance;
}

struct GetFindDataInfo
{
    size_t StructSize;
    HANDLE hPanel;
    PluginPanelItem* PanelItem;
    size_t ItemsNumber;
    OPERATION_MODES OpMode;
	void* Instance;
}

struct FreeFindDataInfo
{
    size_t StructSize;
    HANDLE hPanel;
    PluginPanelItem* PanelItem;
    size_t ItemsNumber;
	void* Instance;
}

struct GetFilesInfo
{
    size_t StructSize;
    HANDLE hPanel;
    PluginPanelItem* PanelItem;
    size_t ItemsNumber;
    BOOL Move;
    const(wchar)* DestPath;
    OPERATION_MODES OpMode;
	void* Instance;
}

struct DeleteFilesInfo
{
    size_t StructSize;
    HANDLE hPanel;
    PluginPanelItem* PanelItem;
    size_t ItemsNumber;
    OPERATION_MODES OpMode;
	void* Instance;
}

struct ProcessPanelInputInfo
{
    size_t StructSize;
    HANDLE hPanel;
    INPUT_RECORD Rec;
	void* Instance;
}

struct ProcessEditorInputInfo
{
    size_t StructSize;
    INPUT_RECORD Rec;
	void* Instance;
}

alias PROCESSCONSOLEINPUT_FLAGS = ulong;
const PROCESSCONSOLEINPUT_FLAGS
    PCIF_NONE     = 0;

struct ProcessConsoleInputInfo
{
    size_t StructSize;
    PROCESSCONSOLEINPUT_FLAGS Flags;
    INPUT_RECORD Rec;
	void* Instance;
}

struct ExitInfo
{
    size_t StructSize;
	void* Instance;
}

struct ProcessPanelEventInfo
{
    size_t StructSize;
    intptr_t Event;
    void* Param;
    HANDLE hPanel;
	void* Instance;
}

struct ProcessEditorEventInfo
{
    size_t StructSize;
    intptr_t Event;
    void* Param;
    intptr_t EditorID;
	void* Instance;
}

struct ProcessDialogEventInfo
{
    size_t StructSize;
    intptr_t Event;
    FarDialogEvent* Param;
	void* Instance;
}

struct ProcessSynchroEventInfo
{
    size_t StructSize;
    intptr_t Event;
    void* Param;
	void* Instance;
}

struct ProcessViewerEventInfo
{
    size_t StructSize;
    intptr_t Event;
    void* Param;
    intptr_t ViewerID;
	void* Instance;
}

struct ClosePanelInfo
{
    size_t StructSize;
    HANDLE hPanel;
	void* Instance;
}

struct CloseAnalyseInfo
{
    size_t StructSize;
    HANDLE Handle;
	void* Instance;
}

struct ConfigureInfo
{
    size_t StructSize;
    const(GUID)* Guid;
	void* Instance;
}

struct GetContentFieldsInfo
{
    size_t StructSize;
    size_t Count;
    const(wchar*)* Names;
    void* Instance;
}

struct GetContentDataInfo
{
    size_t StructSize;
    const(wchar)* FilePath;
    size_t Count;
    const(wchar*)* Names;
    const(wchar)** Values;
    void* Instance;
}

struct ErrorInfo
{
	size_t StructSize;
	const(wchar)* Summary;
	const(wchar)* Description;
}

GUID FarGuid = {0x00000000, 0x0000, 0x0000, [0x00,0x00, 0x00,0x00,0x00,0x00,0x00,0x00]};

// Exported Functions

extern (Windows) HANDLE AnalyseW(in AnalyseInfo* Info);

extern (Windows) void CloseAnalyseW(in CloseAnalyseInfo* Info);

extern (Windows) void ClosePanelW(in ClosePanelInfo* Info);

extern (Windows) intptr_t CompareW(in CompareInfo* Info);

extern (Windows) intptr_t ConfigureW(in ConfigureInfo* Info);

extern (Windows) intptr_t DeleteFilesW(in DeleteFilesInfo* Info);

extern (Windows) void ExitFARW(in ExitInfo* Info);

extern (Windows) void FreeFindDataW(in FreeFindDataInfo* Info);

extern (Windows) intptr_t GetFilesW(GetFilesInfo* Info);

extern (Windows) intptr_t GetFindDataW(GetFindDataInfo* Info);

extern (Windows) void GetGlobalInfoW(GlobalInfo* Info);

extern (Windows) void GetOpenPanelInfoW(OpenPanelInfo* Info);

extern (Windows) void GetPluginInfoW(PluginInfo* Info);

extern (Windows) intptr_t MakeDirectoryW(MakeDirectoryInfo* Info);

extern (Windows) HANDLE OpenW(in OpenInfo* Info);

extern (Windows) intptr_t ProcessDialogEventW(in ProcessDialogEventInfo* Info);

extern (Windows) intptr_t ProcessEditorEventW(in ProcessEditorEventInfo* Info);

extern (Windows) intptr_t ProcessEditorInputW(in ProcessEditorInputInfo* Info);

extern (Windows) intptr_t ProcessPanelEventW(in ProcessPanelEventInfo* Info);

extern (Windows) intptr_t ProcessHostFileW(in ProcessHostFileInfo* Info);

extern (Windows) intptr_t ProcessPanelInputW(in ProcessPanelInputInfo* Info);

extern (Windows) intptr_t ProcessConsoleInputW(ProcessConsoleInputInfo* Info);

extern (Windows) intptr_t ProcessSynchroEventW(in ProcessSynchroEventInfo* Info);

extern (Windows) intptr_t ProcessViewerEventW(in ProcessViewerEventInfo* Info);

extern (Windows) intptr_t PutFilesW(in PutFilesInfo* Info);

extern (Windows) intptr_t SetDirectoryW(in SetDirectoryInfo* Info);

extern (Windows) intptr_t SetFindListW(in SetFindListInfo* Info);

extern (Windows) void SetStartupInfoW(in PluginStartupInfo* Info);

extern (Windows) intptr_t GetContentFieldsW(in GetContentFieldsInfo* Info);

extern (Windows) intptr_t GetContentDataW(GetContentDataInfo* Info);

extern (Windows) void FreeContentDataW(in GetContentDataInfo* Info);
