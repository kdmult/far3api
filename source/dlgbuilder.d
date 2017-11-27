/*
  Dynamic construction of dialogs for FAR Manager 3.0 build 5100

  Original code: http://farmanager.googlecode.com/svn/trunk/plugins/common/unicode/DlgBuilder.hpp
  License: derived from original one without extra restriction
*/

module dlgbuilder;

import farcolor;
import farplugin;

import std.stdint;
import core.sys.windows.windows;
import core.stdc.string;
import core.stdc.stddef;

// Элемент выпадающего списка в диалоге.
struct DialogBuilderListItem
{
    // Строчка из LNG-файла, которая будет показана в диалоге.
    int MessageId;

    // Значение, которое будет записано в поле Value при выборе этой строчки.
    int ItemValue;
}

class DialogItemBinding(T)
{
    int BeforeLabelID = -1;
    int AfterLabelID = -1;

    this()
    {
    }

    void SaveValue(T *Item, int RadioGroupIndex)
    {
    }
}

class CheckBoxBinding(T): DialogItemBinding!T
{
private:
    BOOL* Value;
    int Mask;

public:
    this(int* aValue, int aMask)
    {
        Value = aValue;
        Mask = aMask;
    }

    override void SaveValue(T* Item, int RadioGroupIndex)
    {
        if (!Mask)
        {
            *Value = Item.Selected;
        }
        else
        {
            if (Item.Selected)
                *Value |= Mask;
            else
                *Value &= ~Mask;
        }
    }
}

class RadioButtonBinding(T): DialogItemBinding!T
{
private:
    int* Value;

public:
    this(int* aValue)
    {
        Value = aValue;
    }

    override void SaveValue(T* Item, int RadioGroupIndex)
    {
        if (Item.Selected)
            *Value = RadioGroupIndex;
    }
}

/*
Класс для динамического построения диалогов. Автоматически вычисляет положение и размер
для добавляемых контролов, а также размер самого диалога. Автоматически записывает выбранные
значения в указанное место после закрытия диалога по OK.

По умолчанию каждый контрол размещается в новой строке диалога. Ширина для текстовых строк,
checkbox и radio button вычисляется автоматически, для других элементов передаётся явно.
Есть также возможность добавить статический текст слева или справа от контрола, при помощи
методов AddTextBefore и AddTextAfter.

Поддерживается также возможность расположения контролов в две колонки. Используется следующим
образом:
- StartColumns()
- добавляются контролы для первой колонки
- ColumnBreak()
- добавляются контролы для второй колонки
- EndColumns()

Поддерживается также возможность расположения контролов внутри бокса. Используется следующим
образом:
- StartSingleBox()
- добавляются контролы
- EndSingleBox()

Базовая версия класса используется как внутри кода Far, так и в плагинах.
*/

class DialogBuilderBase(T)
{
protected:
    T* m_DialogItems;
    DialogItemBinding!T[] m_Bindings;
    int m_DialogItemsCount;
    int m_DialogItemsAllocated;
    int m_NextY;
    int m_Indent;
    int m_SingleBoxIndex;
    int m_FirstButtonID;
    int m_CancelButtonID;
    int m_ColumnStartIndex;
    int m_ColumnBreakIndex;
    int m_ColumnStartY;
    int m_ColumnEndY;
    intptr_t m_ColumnMinWidth;
    intptr_t m_ButtonsWidth;

    static const int SECOND_COLUMN = -2;

    void ReallocDialogItems()
    {
        // реаллокация инвалидирует указатели на DialogItemEx, возвращённые из
        // AddDialogItem и аналогичных методов, поэтому размер массива подбираем такой,
        // чтобы все нормальные диалоги помещались без реаллокации
        // TODO хорошо бы, чтобы они вообще не инвалидировались
        m_DialogItemsAllocated += 64;
        if (!m_DialogItems)
        {
            m_DialogItems = new T[m_DialogItemsAllocated].ptr;
            m_Bindings = new DialogItemBinding!T[m_DialogItemsAllocated];
        }
        else
        {
            T* NewDialogItems = new T[m_DialogItemsAllocated].ptr;
            auto NewBindings = new DialogItemBinding!T[m_DialogItemsAllocated];
            for(int i=0; i<m_DialogItemsCount; i++)
            {
                NewDialogItems [i] = m_DialogItems [i];
                NewBindings [i] = m_Bindings [i];
            }
            m_DialogItems.destroy();
            m_Bindings.destroy();
            m_DialogItems = NewDialogItems;
            m_Bindings = NewBindings;
        }
    }

    T* AddDialogItem(FARDIALOGITEMTYPES Type, in wchar* Text)
    {
        if (m_DialogItemsCount == m_DialogItemsAllocated)
        {
            ReallocDialogItems();
        }
        int Index = m_DialogItemsCount++;
        T* Item = &m_DialogItems [Index];
        InitDialogItem(Item, Text);
        Item.Type = Type;
        m_Bindings [Index] = new DialogItemBinding!T;
        return Item;
    }

    void SetNextY(T* Item)
    {
        Item.X1 = 5 + m_Indent;
        Item.Y1 = Item.Y2 = m_NextY++;
    }

    intptr_t ItemWidth(ref const T Item)
    {
        with (FARDIALOGITEMTYPES) switch(Item.Type)
        {
        case DI_TEXT:
            return TextWidth(Item);

        case DI_CHECKBOX:
        case DI_RADIOBUTTON:
        case DI_BUTTON:
            return TextWidth(Item) + 4;

        case DI_EDIT:
        case DI_FIXEDIT:
        case DI_COMBOBOX:
        case DI_LISTBOX:
        case DI_PSWEDIT:
            intptr_t Width = Item.X2 - Item.X1 + 1;
            // стрелка history занимает дополнительное место, но раньше она рисовалась поверх рамки???
            if (Item.Flags & DIF_HISTORY)
                Width++;
            return Width;

        default:
            break;
        }
        return 0;
    }

    void AddBorder(in wchar* TitleText)
    {
        T* Title = AddDialogItem(FARDIALOGITEMTYPES.DI_DOUBLEBOX, TitleText);
        Title.X1 = 3;
        Title.Y1 = 1;
    }

    void UpdateBorderSize()
    {
        T* Title = &m_DialogItems[0];
        intptr_t MaxWidth = MaxTextWidth();
        intptr_t MaxHeight = 0;
        Title.X2 = Title.X1 + MaxWidth - 1 + 4;

        for (int i=1; i<m_DialogItemsCount; i++)
        {
            if (m_DialogItems[i].Type == FARDIALOGITEMTYPES.DI_SINGLEBOX)
            {
                m_Indent = 2;
                m_DialogItems[i].X2 = Title.X2;
            }
            else if (m_DialogItems[i].Type == FARDIALOGITEMTYPES.DI_TEXT && (m_DialogItems[i].Flags & DIF_CENTERTEXT))
            {//BUGBUG: two columns items are not supported
                m_DialogItems[i].X2 = m_DialogItems[i].X1 + MaxWidth - 1;
            }

            if (m_DialogItems[i].Y2 > MaxHeight)
            {
                MaxHeight = m_DialogItems[i].Y2;
            }
        }

        Title.X2 += m_Indent;
        Title.Y2 = MaxHeight + 1;
        m_Indent = 0;
    }

    intptr_t MaxTextWidth()
    {
        intptr_t MaxWidth = 0;
        for(int i=1; i<m_DialogItemsCount; i++)
        {
            if (m_DialogItems [i].X1 == SECOND_COLUMN) continue;
            DialogItemBinding!T Binding = FindBinding(m_DialogItems+i);
            intptr_t Width = ItemWidth(m_DialogItems [i]);
            if (Binding && Binding.BeforeLabelID != -1)
                Width += ItemWidth(m_DialogItems [Binding.BeforeLabelID]) + 1;
            if (Binding && Binding.AfterLabelID != -1)
                Width += 1 + ItemWidth(m_DialogItems [Binding.AfterLabelID]);

            if (MaxWidth < Width)
                MaxWidth = Width;
        }
        intptr_t ColumnsWidth = 2*m_ColumnMinWidth+1;
        if (MaxWidth < ColumnsWidth)
            MaxWidth = ColumnsWidth;
        if (MaxWidth < m_ButtonsWidth)
            MaxWidth = m_ButtonsWidth;
        return MaxWidth;
    }

    void UpdateSecondColumnPosition()
    {
        intptr_t SecondColumnX1 = 4 + (m_DialogItems [0].X2 - m_DialogItems [0].X1 + 1)/2;
        for(int i=0; i<m_DialogItemsCount; i++)
        {
            if (m_DialogItems [i].X1 == SECOND_COLUMN)
            {
                DialogItemBinding!T Binding = FindBinding(m_DialogItems+i);
                
                int before = Binding.BeforeLabelID;
                long BeforeWidth = 0;
                if (Binding && Binding.BeforeLabelID != -1)
                    BeforeWidth = m_DialogItems [before].X2 - m_DialogItems [before].X1 + 1 + 1;
                
                intptr_t Width = m_DialogItems [i].X2 - m_DialogItems [i].X1 + 1;
                m_DialogItems [i].X1 = SecondColumnX1 + BeforeWidth;
                m_DialogItems [i].X2 = m_DialogItems [i].X1 + Width - 1;

                if (Binding && Binding.AfterLabelID != -1)
                {
                    int after = Binding.AfterLabelID;
                    long AfterWidth = m_DialogItems [after].X2 - m_DialogItems [after].X1 + 1;
                    m_DialogItems [after].X1 = m_DialogItems [i].X2 + 1 + 1;
                    m_DialogItems [after].X2 = m_DialogItems [after].X1 + AfterWidth - 1;
                }
            }
        }
    }

    void InitDialogItem(T* NewDialogItem, in wchar* Text)
    {
    }

    int TextWidth(ref const T Item)
    {
        return 0;
    }

    void SetLastItemBinding(DialogItemBinding!T Binding)
    {
        if (m_Bindings [m_DialogItemsCount-1])
            m_Bindings [m_DialogItemsCount-1].destroy();
        m_Bindings [m_DialogItemsCount-1] = Binding;
    }

    int GetItemID(T* Item) const
    {
        int Index = cast(int)(Item - m_DialogItems);
        if (Index >= 0 && Index < m_DialogItemsCount)
            return Index;
        return -1;
    }

    DialogItemBinding!T FindBinding(T* Item)
    {
        int Index = cast(int)(Item - m_DialogItems);
        if (Index >= 0 && Index < m_DialogItemsCount)
            return m_Bindings [Index];
        return null;
    }

    void SaveValues()
    {
        int RadioGroupIndex = 0;
        for(int i=0; i<m_DialogItemsCount; i++)
        {
            if (m_DialogItems [i].Flags & DIF_GROUP)
                RadioGroupIndex = 0;
            else
                RadioGroupIndex++;

            if (m_Bindings [i])
                m_Bindings [i].SaveValue(&m_DialogItems [i], RadioGroupIndex);
        }
    }

    const(wchar)* GetLangString(int MessageID)
    {
        return null;
    }

    intptr_t DoShowDialog()
    {
        return -1;
    }

    DialogItemBinding!T CreateCheckBoxBinding(int* Value, int Mask)
    {
        return null;
    }

    DialogItemBinding!T CreateRadioButtonBinding(int* Value)
    {
        return null;
    }

    this()
    {
        m_NextY = 2;
        m_SingleBoxIndex = -1;
        m_FirstButtonID = -1;
        m_CancelButtonID = -1;
        m_ColumnStartIndex = -1;
        m_ColumnBreakIndex = -1;
        m_ColumnStartY = -1;
        m_ColumnEndY = -1;
    }

    ~this()
    {
        for (int i=0; i<m_DialogItemsCount; i++)
        {
            if (m_Bindings [i])
                m_Bindings [i].destroy();
        }
        m_DialogItems.destroy();
        m_Bindings.destroy();
    }

public:

    int GetLastID() const
    {
        return m_DialogItemsCount-1;
    }

    // Добавляет статический текст, расположенный на отдельной строке в диалоге.
    T* AddText(int LabelId)
    {
        return AddText(LabelId == -1 ? "" : GetLangString(LabelId));
    }

    // Добавляет статический текст, расположенный на отдельной строке в диалоге.
    T* AddText(in wchar* Label)
    {
        T* Item = AddDialogItem(FARDIALOGITEMTYPES.DI_TEXT, Label);
        SetNextY(Item);
        Item.X2 = Item.X1 + ItemWidth(*Item) - 1;
        return Item;
    }

    // Добавляет чекбокс.
    T* AddCheckbox(in wchar* TextMessage, int* Value, int Mask = 0, bool ThreeState = false)
    {
        T* Item = AddDialogItem(FARDIALOGITEMTYPES.DI_CHECKBOX, TextMessage);
        if (ThreeState && !Mask)
            Item.Flags |= DIF_3STATE;
        SetNextY(Item);
        Item.X2 = Item.X1 + ItemWidth(*Item) - 1;
        if (!Mask)
            Item.Selected = *Value;
        else
            Item.Selected = (*Value & Mask) != 0;
        SetLastItemBinding(CreateCheckBoxBinding(Value, Mask));
        return Item;
    }

    // Добавляет чекбокс.
    T* AddCheckbox(int TextMessageId, int *Value, int Mask = 0, bool ThreeState = false)
    {
        return AddCheckbox(GetLangString(TextMessageId), Value, Mask, ThreeState);
    }

    // Добавляет группу радиокнопок.
    T* AddRadioButtons(int* Value, int OptionCount, const int[] MessageIDs, bool FocusOnSelected=false)
    {
        T* firstButton;
        for (int i=0; i<OptionCount; i++)
        {
            T* Item = AddDialogItem(FARDIALOGITEMTYPES.DI_RADIOBUTTON, GetLangString(MessageIDs[i]));
            SetNextY(Item);
            Item.X2 = Item.X1 + ItemWidth(*Item) - 1;
            if (!i)
            {
                Item.Flags |= DIF_GROUP;
                firstButton = Item;
            }
            if (*Value == i)
            {
                Item.Selected = TRUE;
                if (FocusOnSelected)
                    Item.Flags |= DIF_FOCUS;
            }
            SetLastItemBinding(CreateRadioButtonBinding(Value));
        }
        return firstButton;
    }

    void AddRadioButtons(int* Value, const int[] MessageIDs, bool FocusOnSelected=false)
    {
        AddRadioButtons(Value, cast(int) MessageIDs.length, MessageIDs, FocusOnSelected);
    }

    // Добавляет поле типа FARDIALOGITEMTYPES.DI_FIXEDIT для редактирования указанного числового значения.
    T* AddIntEditField(int* Value, int Width)
    {
        return null;
    }

    T* AddUIntEditField(uint* Value, int Width)
    {
        return null;
    }

    // Добавляет указанную текстовую строку слева от элемента RelativeTo.
    T* AddTextBefore(T* RelativeTo, in wchar* Label)
    {
        T* Item = AddDialogItem(FARDIALOGITEMTYPES.DI_TEXT, Label);
        Item.Y1 = Item.Y2 = RelativeTo.Y1;
        Item.X1 = 5 + m_Indent;
        Item.X2 = Item.X1 + ItemWidth(*Item) - 1;

        intptr_t RelativeToWidth = RelativeTo.X2 - RelativeTo.X1 + 1;
        RelativeTo.X1 = Item.X2 + 1 + 1;
        RelativeTo.X2 = RelativeTo.X1 + RelativeToWidth - 1;

        DialogItemBinding!T Binding = FindBinding(RelativeTo);
        if (Binding)
            Binding.BeforeLabelID = GetItemID(Item);

        return Item;
    }

    // Добавляет указанную текстовую строку слева от элемента RelativeTo.
    T* AddTextBefore(T* RelativeTo, int LabelId)
    {
        return AddTextBefore(RelativeTo, GetLangString(LabelId));
    }

    // Добавляет указанную текстовую строку справа от элемента RelativeTo.
    T* AddTextAfter(T* RelativeTo, in wchar* Label)
    {
        T* Item = AddDialogItem(FARDIALOGITEMTYPES.DI_TEXT, Label);
        Item.Y1 = Item.Y2 = RelativeTo.Y1;
        Item.X1 = RelativeTo.X2 + 1 + 1;
        Item.X2 = Item.X1 + ItemWidth(*Item) - 1;

        DialogItemBinding!T Binding = FindBinding(RelativeTo);
        if (Binding)
            Binding.AfterLabelID = GetItemID(Item);

        return Item;
    }

    T* AddTextAfter(T* RelativeTo, int LabelId)
    {
        return AddTextAfter(RelativeTo, GetLangString(LabelId));
    }

    // Добавляет кнопку справа от элемента RelativeTo.
    T* AddButtonAfter(T* RelativeTo, in wchar* Label)
    {
        T* Item = AddDialogItem(FARDIALOGITEMTYPES.DI_BUTTON, Label);
        Item.Y1 = Item.Y2 = RelativeTo.Y1;
        Item.X1 = RelativeTo.X2 + 1 + 1;
        Item.X2 = Item.X1 + ItemWidth(*Item) - 1;

        DialogItemBinding!T Binding = FindBinding(RelativeTo);
        if (Binding)
            Binding.AfterLabelID = GetItemID(Item);

        return Item;
    }

    // Добавляет кнопку справа от элемента RelativeTo.
    T* AddButtonAfter(T* RelativeTo, int LabelId)
    {
        return AddButtonAfter(RelativeTo, GetLangString(LabelId));
    }

    // Начинает располагать поля диалога в две колонки.
    void StartColumns()
    {
        m_ColumnStartIndex = m_DialogItemsCount;
        m_ColumnStartY = m_NextY;
    }

    // Завершает колонку полей в диалоге и переходит к следующей колонке.
    void ColumnBreak()
    {
        m_ColumnBreakIndex = m_DialogItemsCount;
        m_ColumnEndY = m_NextY;
        m_NextY = m_ColumnStartY;
    }

    // Завершает расположение полей диалога в две колонки.
    void EndColumns()
    {
        for(int i=m_ColumnStartIndex; i<m_DialogItemsCount; i++)
        {
            intptr_t Width = ItemWidth(m_DialogItems [i]);
            DialogItemBinding!T Binding = FindBinding(m_DialogItems + i);
            long BindingAdd = 0;
            if (Binding) {
                if (Binding.BeforeLabelID != -1)
                    BindingAdd += ItemWidth(m_DialogItems [Binding.BeforeLabelID]) + 1;
                if (Binding.AfterLabelID != -1)
                    BindingAdd += 1 + ItemWidth(m_DialogItems [Binding.AfterLabelID]);
            }

            if (Width + BindingAdd > m_ColumnMinWidth)
                m_ColumnMinWidth = Width + BindingAdd;

            if (i >= m_ColumnBreakIndex)
            {
                m_DialogItems [i].X1 = SECOND_COLUMN;
                m_DialogItems [i].X2 = SECOND_COLUMN + Width - 1;
            }
        }

        m_ColumnStartIndex = -1;
        m_ColumnBreakIndex = -1;

        if (m_NextY < m_ColumnEndY)
            m_NextY = m_ColumnEndY;
    }

    // Начинает располагать поля диалога внутри single box
    void StartSingleBox(int MessageId=-1, bool LeftAlign=false)
    {
        T* SingleBox = AddDialogItem(FARDIALOGITEMTYPES.DI_SINGLEBOX, MessageId == -1 ? "" : GetLangString(MessageId));
        SingleBox.Flags = LeftAlign ? DIF_LEFTTEXT : DIF_NONE;
        SingleBox.X1 = 5;
        SingleBox.Y1 = m_NextY++;
        m_Indent = 2;
        m_SingleBoxIndex = m_DialogItemsCount - 1;
    }

    // Завершает расположение полей диалога внутри single box
    void EndSingleBox()
    {
        if (m_SingleBoxIndex != -1)
        {
            m_DialogItems[m_SingleBoxIndex].Y2 = m_NextY++;
            m_Indent = 0;
            m_SingleBoxIndex = -1;
        }
    }

    // Добавляет пустую строку.
    void AddEmptyLine()
    {
        m_NextY++;
    }

    // Добавляет сепаратор.
    void AddSeparator(int MessageId=-1)
    {
        return AddSeparator(MessageId == -1 ? "" : GetLangString(MessageId));
    }

    void AddSeparator(in wchar* Text)
    {
        T* Separator = AddDialogItem(FARDIALOGITEMTYPES.DI_TEXT, Text);
        Separator.Flags = DIF_SEPARATOR;
        Separator.X1 = -1;
        Separator.Y1 = Separator.Y2 = m_NextY++;
    }

    // Добавляет сепаратор, кнопки OK и Cancel.
    void AddOKCancel(int OKMessageId, int CancelMessageId, int ExtraMessageId = -1, bool Separator=true)
    {
        if (Separator)
            AddSeparator();

        int[3] MsgIDs = [ OKMessageId, CancelMessageId, ExtraMessageId ];
        int NumButtons = (ExtraMessageId != -1) ? 3 : (CancelMessageId != -1? 2 : 1);

        AddButtons(NumButtons, MsgIDs, 0, 1);
    }

    // Добавляет линейку кнопок.
    void AddButtons(int ButtonCount, const int[] MessageIDs, int defaultButtonIndex = 0, int cancelButtonIndex = -1)
    {
        int LineY = m_NextY++;
        T* PrevButton = null;

        for (int i = 0; i < ButtonCount; i++)
        {
            T* NewButton = AddDialogItem(FARDIALOGITEMTYPES.DI_BUTTON, GetLangString(MessageIDs[i]));
            NewButton.Flags = DIF_CENTERGROUP;
            NewButton.Y1 = NewButton.Y2 = LineY;
            if (PrevButton)
            {
                NewButton.X1 = PrevButton.X2 + 1;
            }
            else
            {
                NewButton.X1 = 2 + m_Indent;
                m_FirstButtonID = m_DialogItemsCount - 1;
            }
            NewButton.X2 = NewButton.X1 + ItemWidth(*NewButton) - 1 + 1;

            if (defaultButtonIndex == i)
            {
                NewButton.Flags |= DIF_DEFAULTBUTTON;
            }
            if (cancelButtonIndex == i)
                m_CancelButtonID = m_DialogItemsCount - 1;

            PrevButton = NewButton;
        }
        auto Width = PrevButton.X2 - 1 - m_DialogItems [m_FirstButtonID].X1 + 1;
        if (m_ButtonsWidth < Width)
            m_ButtonsWidth = Width;
    }

    void AddButtons(const int[] MessageIDs, int defaultButtonIndex = 0, int cancelButtonIndex = -1)
    {
        AddButtons(cast(int) MessageIDs.length, MessageIDs, defaultButtonIndex, cancelButtonIndex);
    }

    intptr_t ShowDialogEx()
    {
        UpdateBorderSize();
        UpdateSecondColumnPosition();
        intptr_t Result = DoShowDialog();
        if (Result >= 0 && Result != m_CancelButtonID)
        {
            SaveValues();
        }

        if (m_FirstButtonID >= 0 && Result >= m_FirstButtonID)
        {
            Result -= m_FirstButtonID;
        }
        return Result;
    }

    bool ShowDialog()
    {
        intptr_t Result = ShowDialogEx();
        return Result >= 0 && (m_CancelButtonID < 0 || Result + m_FirstButtonID != m_CancelButtonID);
    }

}

class DialogAPIBinding: DialogItemBinding!FarDialogItem
{
protected:
    const(PluginStartupInfo)* Info;
    HANDLE* DialogHandle;
    int ID;

    this(in PluginStartupInfo* aInfo, HANDLE* aHandle, int aID)
    {
        Info = aInfo;
        DialogHandle = aHandle;
        ID = aID;
    }
}

class PluginCheckBoxBinding: DialogAPIBinding
{
    int *Value;
    int Mask;

public:
    this(in PluginStartupInfo* aInfo, HANDLE* aHandle, int aID, int* aValue, int aMask)
    {
        super(aInfo, aHandle, aID);
        Value = aValue;
        Mask = aMask;
    }

    override void SaveValue(FarDialogItem* Item, int RadioGroupIndex)
    {
        int Selected = cast(int)(Info.SendDlgMessage(*DialogHandle, FARMESSAGE.DM_GETCHECK, ID, null));
        if (!Mask)
        {
            *Value = Selected;
        }
        else
        {
            if (Selected)
                *Value |= Mask;
            else
                *Value &= ~Mask;
        }
    }
}

class PluginRadioButtonBinding: DialogAPIBinding
{
private:
    int *Value;

public:
    this(in PluginStartupInfo* aInfo, HANDLE* aHandle, int aID, int* aValue)
    {
        super(aInfo, aHandle, aID);
        Value = aValue;
    }

    override void SaveValue(FarDialogItem* Item, int RadioGroupIndex)
    {
        if (Info.SendDlgMessage(*DialogHandle, FARMESSAGE.DM_GETCHECK, ID, null))
            *Value = RadioGroupIndex;
    }
}

class PluginEditFieldBinding: DialogAPIBinding
{
private:
    wchar* Value;
    int MaxSize;

public:
    this(in PluginStartupInfo* aInfo, HANDLE* aHandle, int aID, wchar* aValue, int aMaxSize)
    {
        super(aInfo, aHandle, aID);
        Value = aValue;
        MaxSize = aMaxSize;
    }

    override void SaveValue(FarDialogItem* Item, int RadioGroupIndex)
    {
        const(wchar)* DataPtr = cast(const(wchar)*) Info.SendDlgMessage(*DialogHandle, FARMESSAGE.DM_GETCONSTTEXTPTR, ID, null);
        lstrcpynW(Value, DataPtr, MaxSize);
    }
}

class PluginIntEditFieldBinding: DialogAPIBinding
{
private:
    int* Value;
    wchar[32] Buffer;
    wchar[32] Mask;

public:
    this(in PluginStartupInfo* aInfo, HANDLE* aHandle, int aID, int* aValue, int Width)
    {
        super(aInfo, aHandle, aID);
        Value = aValue;
        aInfo.FSF.sprintf(Buffer.ptr, "%d"w.ptr, *aValue);
        int MaskWidth = Width < 31 ? Width : 31;
        for(int i=1; i<MaskWidth; i++)
            Mask[i] = '9';
        Mask[0] = '#';
        Mask[MaskWidth] = '\0';
    }

    override void SaveValue(FarDialogItem* Item, int RadioGroupIndex)
    {
        wchar* DataPtr = cast(wchar*) Info.SendDlgMessage(*DialogHandle, FARMESSAGE.DM_GETCONSTTEXTPTR, ID, null);
        *Value = Info.FSF.atoi(DataPtr);
    }

    wchar* GetBuffer()
    {
        return Buffer.ptr;
    }

    const(wchar)* GetMask() const
    {
        return Mask.ptr;
    }
}

class PluginUIntEditFieldBinding: DialogAPIBinding
{
private:
    uint* Value;
    wchar[32] Buffer;
    wchar[32] Mask;

public:
    this(in PluginStartupInfo* aInfo, HANDLE* aHandle, int aID, uint* aValue, int Width)
    {
        super(aInfo, aHandle, aID);
        Value = aValue;
        aInfo.FSF.sprintf(Buffer.ptr, "%u"w.ptr, *aValue);
        int MaskWidth = Width < 31 ? Width : 31;
        for(int i=1; i<MaskWidth; i++)
            Mask[i] = '9';
        Mask[0] = '#';
        Mask[MaskWidth] = '\0';
    }

    override void SaveValue(FarDialogItem* Item, int RadioGroupIndex)
    {
        wchar* DataPtr = cast(wchar*) Info.SendDlgMessage(*DialogHandle, FARMESSAGE.DM_GETCONSTTEXTPTR, ID, null);
        *Value = cast(uint)Info.FSF.atoi64(DataPtr);
    }

    wchar* GetBuffer()
    {
        return Buffer.ptr;
    }

    const(wchar)* GetMask() const
    {
        return Mask.ptr;
    }
}

class PluginListControlBinding : DialogAPIBinding
{
private:
    int* SelectedIndex;
    wchar* TextBuf;
    FarList* List;
    
public:
    this(in PluginStartupInfo* aInfo, HANDLE* aHandle, int aID, int* aValue, wchar* aText, FarList* aList)
    {
        super(aInfo, aHandle, aID);
        SelectedIndex = aValue;
        TextBuf = aText;
        List = aList;
    }

    this(in PluginStartupInfo* aInfo, HANDLE* aHandle, int aID, int* aValue, FarList* aList)
    {
        super(aInfo, aHandle, aID);
        SelectedIndex = aValue;
        List = aList;
    }

    ~this()
    {
        if (List)
        {
            List.Items.destroy();
        }
        List.destroy();
    }

    override void SaveValue(FarDialogItem* Item, int RadioGroupIndex)
    {
        if (SelectedIndex)
        {
            *SelectedIndex = cast(int)(Info.SendDlgMessage(*DialogHandle, FARMESSAGE.DM_LISTGETCURPOS, ID, null));
        }
        if (TextBuf)
        {
            FarDialogItemData fdid = {FarDialogItemData.sizeof, 0, TextBuf};
            Info.SendDlgMessage(*DialogHandle, FARMESSAGE.DM_GETTEXT, ID, &fdid);
        }
    }
}

/*
Версия класса для динамического построения диалогов, используемая в плагинах к Far.
*/
class PluginDialogBuilder: DialogBuilderBase!FarDialogItem
{
protected:
    const(PluginStartupInfo)* Info;
    HANDLE DialogHandle;
    const(wchar)* HelpTopic;
    GUID PluginId;
    GUID Id;
    FARWINDOWPROC DlgProc;
    void* UserParam;
    FARDIALOGFLAGS Flags;

    override void InitDialogItem(FarDialogItem* Item, in wchar* Text)
    {
        memset(Item, 0, FarDialogItem.sizeof);
        Item.Data = Text;
    }

    override int TextWidth(ref const FarDialogItem Item)
    {
        return lstrlenW(Item.Data);
    }

    override const(wchar)* GetLangString(int MessageID)
    {
        return Info.GetMsg(&PluginId, MessageID);
    }

    override intptr_t DoShowDialog()
    {
        intptr_t Width = m_DialogItems[0].X2+4;
        intptr_t Height = m_DialogItems[0].Y2+2;
        DialogHandle = Info.DialogInit(&PluginId, &Id, -1, -1, Width, Height, HelpTopic, m_DialogItems, m_DialogItemsCount, 0, Flags, DlgProc, UserParam);
        return Info.DialogRun(DialogHandle);
    }

    override DialogItemBinding!FarDialogItem CreateCheckBoxBinding(int* Value, int Mask)
    {
        return new PluginCheckBoxBinding(Info, &DialogHandle, m_DialogItemsCount-1, Value, Mask);
    }

    override DialogItemBinding!FarDialogItem CreateRadioButtonBinding(BOOL* Value)
    {
        return new PluginRadioButtonBinding(Info, &DialogHandle, m_DialogItemsCount-1, Value);
    }

    FarDialogItem* AddListControl(FARDIALOGITEMTYPES Type, int* SelectedItem, wchar* Text, int Width, int Height, in wchar*[] ItemsText, size_t ItemCount, FARDIALOGITEMFLAGS ItemFlags)
    {
        FarDialogItem* Item = AddDialogItem(Type, Text ? Text : "");
        SetNextY(Item);
        Item.X2 = Item.X1 + Width;
        Item.Y2 = Item.Y2 + Height;
        Item.Flags |= ItemFlags;

        m_NextY += Height;

        FarListItem* ListItems;
        if (ItemsText)
        {
            ListItems = new FarListItem[ItemCount].ptr;
            for(size_t i=0; i<ItemCount; i++)
            {
                ListItems[i].Text = ItemsText[i];
                ListItems[i].Flags = SelectedItem && (*SelectedItem == cast(int)i) ? LIF_SELECTED : 0;
            }
        }
        FarList* List = new FarList;
        List.StructSize = FarList.sizeof;
        List.Items = ListItems;
        List.ItemsNumber = ListItems ? ItemCount : 0;
        Item.ListItems = List;

        SetLastItemBinding(new PluginListControlBinding(Info, &DialogHandle, m_DialogItemsCount - 1, SelectedItem, Text, List));
        return Item;
    }

    FarDialogItem* AddListControl(FARDIALOGITEMTYPES Type, int* SelectedItem, wchar* Text, int Width, int Height, const int[] MessageIDs, size_t ItemCount, FARDIALOGITEMFLAGS ItemFlags)
    {
        const(wchar)*[] ItemsText;
        if (MessageIDs)
        {
            ItemsText = new const(wchar)*[ItemCount];
            for (size_t i = 0; i < ItemCount; i++)
            {
                ItemsText[i] = GetLangString(MessageIDs[i]);
            }
        }

        FarDialogItem* result = AddListControl(Type, SelectedItem, Text, Width, Height, ItemsText, ItemCount, ItemFlags);

        ItemsText.destroy();

        return result;
    }

public:
    this(in PluginStartupInfo* aInfo, ref const GUID aPluginId, ref const GUID aId, int TitleMessageID, in wchar* aHelpTopic, FARWINDOWPROC aDlgProc=null, void* aUserParam=null, FARDIALOGFLAGS aFlags = FDLG_NONE)
    {
        Info = aInfo;
        HelpTopic = aHelpTopic;
        PluginId = aPluginId;
        Id = aId;
        DlgProc = aDlgProc;
        UserParam = aUserParam;
        Flags = aFlags;
        AddBorder(PluginDialogBuilder.GetLangString(TitleMessageID));
    }

    this(in PluginStartupInfo* aInfo, ref const GUID aPluginId, ref const GUID aId, in wchar* TitleMessage, in wchar* aHelpTopic, FARWINDOWPROC aDlgProc=null, void* aUserParam=null, FARDIALOGFLAGS aFlags = FDLG_NONE)
    {
        Info = aInfo;
        HelpTopic = aHelpTopic;
        PluginId = aPluginId;
        Id = aId;
        DlgProc = aDlgProc;
        UserParam = aUserParam;
        Flags = aFlags;
        AddBorder(TitleMessage);
    }

    ~this()
    {
        Info.DialogFree(DialogHandle);
    }

    override FarDialogItem* AddIntEditField(int* Value, int Width)
    {
        FarDialogItem* Item = AddDialogItem(FARDIALOGITEMTYPES.DI_FIXEDIT, "");
        Item.Flags |= DIF_MASKEDIT;
        auto Binding = new PluginIntEditFieldBinding(Info, &DialogHandle, m_DialogItemsCount-1, Value, Width);
        Item.Data = Binding.GetBuffer();
        Item.Mask = Binding.GetMask();
        SetNextY(Item);
        Item.X2 = Item.X1 + Width - 1;
        SetLastItemBinding(Binding);
        return Item;
    }

    override FarDialogItem* AddUIntEditField(uint* Value, int Width)
    {
        FarDialogItem* Item = AddDialogItem(FARDIALOGITEMTYPES.DI_FIXEDIT, "");
        Item.Flags |= DIF_MASKEDIT;
        auto Binding = new PluginUIntEditFieldBinding(Info, &DialogHandle, m_DialogItemsCount-1, Value, Width);
        Item.Data = Binding.GetBuffer();
        Item.Mask = Binding.GetMask();
        SetNextY(Item);
        Item.X2 = Item.X1 + Width - 1;
        SetLastItemBinding(Binding);
        return Item;
    }

    FarDialogItem* AddEditField(wchar* Value, int MaxSize, int Width, in wchar* HistoryID = null, bool UseLastHistory = false)
    {
        FarDialogItem* Item = AddDialogItem(FARDIALOGITEMTYPES.DI_EDIT, Value);
        SetNextY(Item);
        Item.X2 = Item.X1 + Width - 1;
        if (HistoryID)
        {
            Item.History = HistoryID;
            Item.Flags |= DIF_HISTORY;
            if (UseLastHistory)
                Item.Flags |= DIF_USELASTHISTORY;
        }

        SetLastItemBinding(new PluginEditFieldBinding(Info, &DialogHandle, m_DialogItemsCount-1, Value, MaxSize));
        return Item;
    }

    FarDialogItem* AddPasswordField(wchar* Value, int MaxSize, int Width)
    {
        FarDialogItem* Item = AddDialogItem(FARDIALOGITEMTYPES.DI_PSWEDIT, Value);
        SetNextY(Item);
        Item.X2 = Item.X1 + Width - 1;

        SetLastItemBinding(new PluginEditFieldBinding(Info, &DialogHandle, m_DialogItemsCount-1, Value, MaxSize));
        return Item;
    }

    FarDialogItem* AddFixEditField(wchar* Value, int MaxSize, int Width, in wchar* Mask = null)
    {
        FarDialogItem* Item = AddDialogItem(FARDIALOGITEMTYPES.DI_FIXEDIT, Value);
        SetNextY(Item);
        Item.X2 = Item.X1 + Width - 1;
        if (Mask)
        {
            Item.Mask = Mask;
            Item.Flags |= DIF_MASKEDIT;
        }

        SetLastItemBinding(new PluginEditFieldBinding(Info, &DialogHandle, m_DialogItemsCount-1, Value, MaxSize));
        return Item;
    }

    FarDialogItem* AddComboBox(int* SelectedItem, wchar* Text, int Width, in wchar*[] ItemsText, size_t ItemCount, FARDIALOGITEMFLAGS ItemFlags)
    {
        return AddListControl(FARDIALOGITEMTYPES.DI_COMBOBOX, SelectedItem, Text, Width, 0, ItemsText, ItemCount, ItemFlags);
    }
    FarDialogItem* AddComboBox(int* SelectedItem, wchar* Text, int Width, in wchar*[] ItemsText, FARDIALOGITEMFLAGS ItemFlags)
    {
        return AddComboBox(SelectedItem, Text, Width, ItemsText, ItemsText.length, ItemFlags);
    }

    FarDialogItem* AddComboBox(int* SelectedItem, wchar* Text, int Width, const int[] MessageIDs, size_t ItemCount, FARDIALOGITEMFLAGS ItemFlags)
    {
        return AddListControl(FARDIALOGITEMTYPES.DI_COMBOBOX, SelectedItem, Text, Width, 0, MessageIDs, ItemCount, ItemFlags);
    }
    FarDialogItem* AddComboBox(int* SelectedItem, wchar* Text, int Width, const int[] MessageIDs, FARDIALOGITEMFLAGS ItemFlags)
    {
        return AddComboBox(SelectedItem, Text, Width, MessageIDs, MessageIDs.length, ItemFlags);
    }

    FarDialogItem* AddListBox(int* SelectedItem, int Width, int Height, in wchar*[] ItemsText, size_t ItemCount, FARDIALOGITEMFLAGS ItemFlags)
    {
        return AddListControl(FARDIALOGITEMTYPES.DI_LISTBOX, SelectedItem, null, Width, Height, ItemsText, ItemCount, ItemFlags);
    }
    FarDialogItem* AddListBox(int* SelectedItem, int Width, int Height, in wchar*[] ItemsText, FARDIALOGITEMFLAGS ItemFlags)
    {
        return AddListBox(SelectedItem, Width, Height, ItemsText, ItemsText.length, ItemFlags);
    }

    FarDialogItem* AddListBox(int* SelectedItem, int Width, int Height, const int[] MessageIDs, size_t ItemCount, FARDIALOGITEMFLAGS ItemFlags)
    {
        return AddListControl(FARDIALOGITEMTYPES.DI_LISTBOX, SelectedItem, null, Width, Height, MessageIDs, ItemCount, ItemFlags);
    }
    FarDialogItem* AddListBox(int* SelectedItem, int Width, int Height, const int[] MessageIDs, FARDIALOGITEMFLAGS ItemFlags)
    {
        return AddListBox(SelectedItem, Width, Height, MessageIDs, MessageIDs.length, ItemFlags);
    }
}
