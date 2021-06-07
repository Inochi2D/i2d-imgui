module bindbc.imgui.bind.imgui;

import core.stdc.stdio;

import core.stdc.stdarg;

extern (C) {
alias ImU32 = uint;
alias ImGuiSizeCallback = void function(ImGuiSizeCallbackData* data);
alias ImGuiContextHookCallback = void function(ImGuiContext* ctx,ImGuiContextHook* hook);
alias ImS8 = byte;
alias ImU64 = ulong;
alias ImWchar = ImWchar16;
alias ImGuiID = uint;
alias ImGuiTableDrawChannelIdx = ImU8;
alias ImGuiInputTextCallback = int function(ImGuiInputTextCallbackData* data);
alias ImDrawIdx = ushort;
alias ImPoolIdx = int;
alias ImDrawCallback = void function(const ImDrawList* parent_list,const ImDrawCmd* cmd);
alias ImS32 = int;
alias ImGuiMemFreeFunc = void function(void* ptr,void* user_data);
    struct ImGuiTableColumnsSettings;
alias ImU16 = ushort;
alias ImWchar16 = ushort;
alias ImS64 = long;
alias ImWchar32 = uint;
alias ImFileHandle = FILE*;
alias ImU8 = char;
alias ImGuiErrorLogCallback = void function(void* user_data,const(char)* fmt,...);
alias ImGuiTableColumnIdx = ImS8;
alias ImTextureID = void*;
alias ImGuiMemAllocFunc = void* function(size_t sz,void* user_data);
alias ImS16 = short;
    
    struct ImVector(tType) {
        int Size;
        int Capacity;
        tType* Data;
    
        import core.stdc.string;
    
    
        bool empty() const                       
        {
            return Size == 0; 
        }
    
        int size() const                        
        {
            return Size; 
        }
    
        int size_in_bytes() const               
        {
            return Size * cast(int)tType.sizeof; 
        }
    
        int max_size() const                    
        {
            return 0x7FFFFFFF / cast(int)tType.sizeof; 
        }
    
        int capacity() const                    
        {
            return Capacity; 
        }
    
        void clear()                             
        {
            if (Data) 
            {
                Size = Capacity = 0;
                igMemFree(Data);
                Data = null; 
            } 
        }
    
        void swap(ImVector* rhs)
        {
            int rhs_size = rhs.Size;
            rhs.Size = Size;
            Size = rhs_size;
            int rhs_cap = rhs.Capacity;
            rhs.Capacity = Capacity;
            Capacity = rhs_cap;
            tType* rhs_data = rhs.Data;
            rhs.Data = Data;
            Data = rhs_data;
        }
    
        int _grow_capacity(int sz) const        
        {
            int new_capacity = Capacity ? (Capacity + Capacity / 2) : 8;
            return new_capacity > sz ? new_capacity : sz; 
        }
    
        void resize(int new_size)                
        {
            if (new_size > Capacity) 
                reserve(_grow_capacity(new_size)); Size = new_size; 
        }
    
        void resize(int new_size, const tType* v)    
        {
            if (new_size > Capacity)
                reserve(_grow_capacity(new_size));
            if (new_size > Size)
                for (int n = Size; n < new_size; n++) 
                    memcpy(&Data[n], v, tType.sizeof); 
            
            Size = new_size; 
        }
    
        // Resize a vector to a smaller size, guaranteed not to cause a reallocation
        void shrink(int new_size)                
        {
            assert(new_size <= Size);
            Size = new_size; 
        } 
    
        void reserve(int new_capacity)           
        {
            if (new_capacity <= Capacity) 
                return; 
    
            tType* new_data = cast(tType*)igMemAlloc(cast(size_t)new_capacity * tType.sizeof); 
            
            if (Data) 
            {
                memcpy(new_data, Data, cast(size_t)Size * tType.sizeof); 
                igMemFree(Data);
            } 
    
            Data = new_data; 
            Capacity = new_capacity; 
        }
    
    
        // NB: It is illegal to call push_back/push_front/insert with a reference pointing inside the ImVector data itself! e.g. v.push_back(v[10]) is forbidden.
        void push_back(const tType* v)               
        {
            if (Size == Capacity)
                reserve(_grow_capacity(Size + 1)); 
            
            memcpy(&Data[Size], v, tType.sizeof);
            Size++; 
        }
    
        void pop_back()                          
        {
             assert(Size > 0);
             Size--; 
        }
    
        void push_front(const tType* v)              
        {
            if (Size == 0)
                push_back(v); 
            else 
                insert(Data, v); 
        }
    
        tType* erase(const tType* it)
        {
             assert(it >= Data && it < Data + Size);
             const ptrdiff_t off = it - Data;
             memmove(Data + off, Data + off + 1, (cast(size_t)Size - cast(size_t)off - 1) * tType.sizeof);
             Size--;
             return Data + off; 
        }
    
        tType* erase(const tType* it, const tType* it_last)
        {
             assert(it >= Data && it < Data + Size && it_last > it && it_last <= Data + Size);
             const ptrdiff_t count = it_last - it;
             const ptrdiff_t off = it - Data;
             memmove(Data + off, Data + off + count, (cast(size_t)Size - cast(size_t)off - count) * tType.sizeof);
             Size -= cast(int)count;
             return Data + off; 
        }
    
        tType* erase_unsorted(const tType* it)
        {
            assert(it >= Data && it < Data + Size);
            const ptrdiff_t off = it - Data;
             
            if (it < Data + Size - 1)
                memcpy(Data + off, Data + Size - 1, tType.sizeof);
            
            Size--;
            return Data + off; 
        }
    
        tType* insert(const tType* it, const tType* v)
        {
             assert(it >= Data && it <= Data + Size); 
             const ptrdiff_t off = it - Data;
             
            if (Size == Capacity) 
                reserve(_grow_capacity(Size + 1));
            
            if (off < cast(int)Size) 
                memmove(Data + off + 1, Data + off, (cast(size_t)Size - cast(size_t)off) * tType.sizeof);
    
            memcpy(&Data[off], v, tType.sizeof);
            Size++;
            return Data + off; 
        }
    }
    
    struct ImSpan(tType) {
        tType* Data;
        tType* DataEnd;
    
        // Constructors, destructor
        //this() 
        //{
        //    Data = DataEnd = NULL; 
        //}
    
        this(tType* data, int size)
        {
            Data = data;
            DataEnd = data + size; 
        }
    
        this(tType* data, tType* data_end)
        {
            Data = data;
            DataEnd = data_end; 
        }
    
        void set(tType* data, int size)
        {
                Data = data;
                DataEnd = data + size; 
        }
    
        void set(tType* data, tType* data_end)
        {
            Data = data;
            DataEnd = data_end; 
        }
    
        int size() const 
        {
            return cast(int)cast(ptrdiff_t)(DataEnd - Data); 
        }
    
        int size_in_bytes() const 
        {
            return cast(int)cast(ptrdiff_t)(DataEnd - Data) * cast(int)tType.sizeof;
        }
    
        tType* opIndex(size_t i)
        {
            tType* p = Data + i;
            assert(p >= Data && p < DataEnd);
            return p; 
        }
    
        tType* begin() 
        {
            return Data; 
        }
    
        tType* end() 
        {
            return DataEnd; 
        }
    
        // Utilities
        int  index_from_ptr(const tType* it)
        { 
            assert(it >= Data && it < DataEnd); 
            const ptrdiff_t off = it - Data;
            return cast(int)off; 
        }
    }
    
    struct ImPool_ImGuiTabBar {
        ImGuiTabBar Buf;
        ImGuiStorage Map;
        ImPoolIdx FreeIdx;
    }
    
    struct ImChunkStream_ImGuiWindowSettings {
        ImGuiWindowSettings Buf;
    }
    
    struct ImChunkStream_ImGuiTableSettings {
        ImGuiTableSettings Buf;
    }
    
    struct ImPool_ImGuiTable {
        ImGuiTable Buf;
        ImGuiStorage Map;
        ImPoolIdx FreeIdx;
    }

    enum ImGuiTableBgTarget{
        None = 0,
        RowBg0 = 1,
        RowBg1 = 2,
        CellBg = 3,
    }

    enum ImGuiLayoutType{
        Horizontal = 0,
        Vertical = 1,
    }

    enum ImGuiNextItemDataFlags{
        None = 0,
        HasWidth = 1,
        HasOpen = 2,
    }

    enum ImGuiItemStatusFlags{
        None = 0,
        HoveredRect = 1,
        HasDisplayRect = 2,
        Edited = 4,
        ToggledSelection = 8,
        ToggledOpen = 16,
        HasDeactivated = 32,
        Deactivated = 64,
        HoveredWindow = 128,
    }

    enum ImGuiSliderFlagsPrivate{
        ImGuiSliderFlags_Vertical = 1048576,
        ImGuiSliderFlags_ReadOnly = 2097152,
    }

    enum ImGuiInputReadMode{
        Down = 0,
        Pressed = 1,
        Released = 2,
        Repeat = 3,
        RepeatSlow = 4,
        RepeatFast = 5,
    }

    enum ImGuiMouseButton{
        Left = 0,
        Right = 1,
        Middle = 2,
        COUNT = 5,
    }

    enum ImGuiSortDirection{
        None = 0,
        Ascending = 1,
        Descending = 2,
    }

    enum ImGuiNavDirSourceFlags{
        None = 0,
        Keyboard = 1,
        PadDPad = 2,
        PadLStick = 4,
    }

    enum ImGuiTabBarFlagsPrivate{
        ImGuiTabBarFlags_DockNode = 1048576,
        ImGuiTabBarFlags_IsFocused = 2097152,
        ImGuiTabBarFlags_SaveSettings = 4194304,
    }

    enum ImGuiTableColumnFlags{
        None = 0,
        DefaultHide = 1,
        DefaultSort = 2,
        WidthStretch = 4,
        WidthFixed = 8,
        NoResize = 16,
        NoReorder = 32,
        NoHide = 64,
        NoClip = 128,
        NoSort = 256,
        NoSortAscending = 512,
        NoSortDescending = 1024,
        NoHeaderWidth = 2048,
        PreferSortAscending = 4096,
        PreferSortDescending = 8192,
        IndentEnable = 16384,
        IndentDisable = 32768,
        IsEnabled = 1048576,
        IsVisible = 2097152,
        IsSorted = 4194304,
        IsHovered = 8388608,
        WidthMask_ = 12,
        IndentMask_ = 49152,
        StatusMask_ = 15728640,
        NoDirectResize_ = 1073741824,
    }

    enum ImGuiTooltipFlags{
        None = 0,
        OverridePreviousTooltip = 1,
    }

    enum ImGuiTabItemFlags{
        None = 0,
        UnsavedDocument = 1,
        SetSelected = 2,
        NoCloseWithMiddleMouseButton = 4,
        NoPushId = 8,
        NoTooltip = 16,
        NoReorder = 32,
        Leading = 64,
        Trailing = 128,
    }

    enum ImGuiPopupPositionPolicy{
        Default = 0,
        ComboBox = 1,
        Tooltip = 2,
    }

    enum ImGuiConfigFlags{
        None = 0,
        NavEnableKeyboard = 1,
        NavEnableGamepad = 2,
        NavEnableSetMousePos = 4,
        NavNoCaptureKeyboard = 8,
        NoMouse = 16,
        NoMouseCursorChange = 32,
        IsSRGB = 1048576,
        IsTouchScreen = 2097152,
    }

    enum ImGuiKeyModFlags{
        None = 0,
        Ctrl = 1,
        Shift = 2,
        Alt = 4,
        Super = 8,
    }

    enum ImGuiDataTypePrivate{
        ImGuiDataType_String = 11,
        ImGuiDataType_Pointer = 12,
        ImGuiDataType_ID = 13,
    }

    enum ImGuiNavInput{
        Activate = 0,
        Cancel = 1,
        Input = 2,
        Menu = 3,
        DpadLeft = 4,
        DpadRight = 5,
        DpadUp = 6,
        DpadDown = 7,
        LStickLeft = 8,
        LStickRight = 9,
        LStickUp = 10,
        LStickDown = 11,
        FocusPrev = 12,
        FocusNext = 13,
        TweakSlow = 14,
        TweakFast = 15,
        KeyMenu_ = 16,
        KeyLeft_ = 17,
        KeyRight_ = 18,
        KeyUp_ = 19,
        KeyDown_ = 20,
        COUNT = 21,
        InternalStart_ = 16,
    }

    enum ImGuiTableRowFlags{
        None = 0,
        Headers = 1,
    }

    enum ImGuiDir{
        None = -1,
        Left = 0,
        Right = 1,
        Up = 2,
        Down = 3,
        COUNT = 4,
    }

    enum ImGuiNavMoveFlags{
        None = 0,
        LoopX = 1,
        LoopY = 2,
        WrapX = 4,
        WrapY = 8,
        AllowCurrentNavId = 16,
        AlsoScoreVisibleSet = 32,
        ScrollToEdge = 64,
    }

    enum ImGuiTextFlags{
        None = 0,
        NoWidthForLargeClippedText = 1,
    }

    enum ImGuiColorEditFlags{
        None = 0,
        NoAlpha = 2,
        NoPicker = 4,
        NoOptions = 8,
        NoSmallPreview = 16,
        NoInputs = 32,
        NoTooltip = 64,
        NoLabel = 128,
        NoSidePreview = 256,
        NoDragDrop = 512,
        NoBorder = 1024,
        AlphaBar = 65536,
        AlphaPreview = 131072,
        AlphaPreviewHalf = 262144,
        HDR = 524288,
        DisplayRGB = 1048576,
        DisplayHSV = 2097152,
        DisplayHex = 4194304,
        Uint8 = 8388608,
        Float = 16777216,
        PickerHueBar = 33554432,
        PickerHueWheel = 67108864,
        InputRGB = 134217728,
        InputHSV = 268435456,
        OptionsDefault = 177209344,
        DisplayMask = 7340032,
        DataTypeMask = 25165824,
        PickerMask = 100663296,
        InputMask = 402653184,
    }

    enum ImGuiTreeNodeFlags{
        None = 0,
        Selected = 1,
        Framed = 2,
        AllowItemOverlap = 4,
        NoTreePushOnOpen = 8,
        NoAutoOpenOnLog = 16,
        DefaultOpen = 32,
        OpenOnDoubleClick = 64,
        OpenOnArrow = 128,
        Leaf = 256,
        Bullet = 512,
        FramePadding = 1024,
        SpanAvailWidth = 2048,
        SpanFullWidth = 4096,
        NavLeftJumpsBackHere = 8192,
        CollapsingHeader = 26,
    }

    enum ImGuiContextHookType{
        NewFramePre = 0,
        NewFramePost = 1,
        EndFramePre = 2,
        EndFramePost = 3,
        RenderPre = 4,
        RenderPost = 5,
        Shutdown = 6,
        PendingRemoval_ = 7,
    }

    enum ImGuiTabBarFlags{
        None = 0,
        Reorderable = 1,
        AutoSelectNewTabs = 2,
        TabListPopupButton = 4,
        NoCloseWithMiddleMouseButton = 8,
        NoTabListScrollingButtons = 16,
        NoTooltip = 32,
        FittingPolicyResizeDown = 64,
        FittingPolicyScroll = 128,
        FittingPolicyMask_ = 192,
        FittingPolicyDefault_ = 64,
    }

    enum ImDrawListFlags{
        None = 0,
        AntiAliasedLines = 1,
        AntiAliasedLinesUseTex = 2,
        AntiAliasedFill = 4,
        AllowVtxOffset = 8,
    }

    enum ImGuiWindowFlags{
        None = 0,
        NoTitleBar = 1,
        NoResize = 2,
        NoMove = 4,
        NoScrollbar = 8,
        NoScrollWithMouse = 16,
        NoCollapse = 32,
        AlwaysAutoResize = 64,
        NoBackground = 128,
        NoSavedSettings = 256,
        NoMouseInputs = 512,
        MenuBar = 1024,
        HorizontalScrollbar = 2048,
        NoFocusOnAppearing = 4096,
        NoBringToFrontOnFocus = 8192,
        AlwaysVerticalScrollbar = 16384,
        AlwaysHorizontalScrollbar = 32768,
        AlwaysUseWindowPadding = 65536,
        NoNavInputs = 262144,
        NoNavFocus = 524288,
        UnsavedDocument = 1048576,
        NoNav = 786432,
        NoDecoration = 43,
        NoInputs = 786944,
        NavFlattened = 8388608,
        ChildWindow = 16777216,
        Tooltip = 33554432,
        Popup = 67108864,
        Modal = 134217728,
        ChildMenu = 268435456,
    }

    enum ImGuiCond{
        None = 0,
        Always = 1,
        Once = 2,
        FirstUseEver = 4,
        Appearing = 8,
    }

    enum ImGuiSelectableFlags{
        None = 0,
        DontClosePopups = 1,
        SpanAllColumns = 2,
        AllowDoubleClick = 4,
        Disabled = 8,
        AllowItemOverlap = 16,
    }

    enum ImGuiNextWindowDataFlags{
        None = 0,
        HasPos = 1,
        HasSize = 2,
        HasContentSize = 4,
        HasCollapsed = 8,
        HasSizeConstraint = 16,
        HasFocus = 32,
        HasBgAlpha = 64,
        HasScroll = 128,
    }

    enum ImGuiStyleVar{
        Alpha = 0,
        WindowPadding = 1,
        WindowRounding = 2,
        WindowBorderSize = 3,
        WindowMinSize = 4,
        WindowTitleAlign = 5,
        ChildRounding = 6,
        ChildBorderSize = 7,
        PopupRounding = 8,
        PopupBorderSize = 9,
        FramePadding = 10,
        FrameRounding = 11,
        FrameBorderSize = 12,
        ItemSpacing = 13,
        ItemInnerSpacing = 14,
        IndentSpacing = 15,
        CellPadding = 16,
        ScrollbarSize = 17,
        ScrollbarRounding = 18,
        GrabMinSize = 19,
        GrabRounding = 20,
        TabRounding = 21,
        ButtonTextAlign = 22,
        SelectableTextAlign = 23,
        COUNT = 24,
    }

    enum ImGuiComboFlags{
        None = 0,
        PopupAlignLeft = 1,
        HeightSmall = 2,
        HeightRegular = 4,
        HeightLarge = 8,
        HeightLargest = 16,
        NoArrowButton = 32,
        NoPreview = 64,
        HeightMask_ = 30,
    }

    enum ImGuiBackendFlags{
        None = 0,
        HasGamepad = 1,
        HasMouseCursors = 2,
        HasSetMousePos = 4,
        RendererHasVtxOffset = 8,
    }

    enum ImFontAtlasFlags{
        None = 0,
        NoPowerOfTwoHeight = 1,
        NoMouseCursors = 2,
        NoBakedLines = 4,
    }

    enum ImGuiItemFlags{
        None = 0,
        NoTabStop = 1,
        ButtonRepeat = 2,
        Disabled = 4,
        NoNav = 8,
        NoNavDefaultFocus = 16,
        SelectableDontClosePopup = 32,
        MixedValue = 64,
        ReadOnly = 128,
        Default_ = 0,
    }

    enum ImGuiNavLayer{
        Main = 0,
        Menu = 1,
        COUNT = 2,
    }

    enum ImGuiAxis{
        None = -1,
        X = 0,
        Y = 1,
    }

    enum ImGuiButtonFlagsPrivate{
        ImGuiButtonFlags_PressedOnClick = 16,
        ImGuiButtonFlags_PressedOnClickRelease = 32,
        ImGuiButtonFlags_PressedOnClickReleaseAnywhere = 64,
        ImGuiButtonFlags_PressedOnRelease = 128,
        ImGuiButtonFlags_PressedOnDoubleClick = 256,
        ImGuiButtonFlags_PressedOnDragDropHold = 512,
        ImGuiButtonFlags_Repeat = 1024,
        ImGuiButtonFlags_FlattenChildren = 2048,
        ImGuiButtonFlags_AllowItemOverlap = 4096,
        ImGuiButtonFlags_DontClosePopups = 8192,
        ImGuiButtonFlags_Disabled = 16384,
        ImGuiButtonFlags_AlignTextBaseLine = 32768,
        ImGuiButtonFlags_NoKeyModifiers = 65536,
        ImGuiButtonFlags_NoHoldingActiveId = 131072,
        ImGuiButtonFlags_NoNavFocus = 262144,
        ImGuiButtonFlags_NoHoveredOnFocus = 524288,
        ImGuiButtonFlags_PressedOnMask_ = 1008,
        ImGuiButtonFlags_PressedOnDefault_ = 32,
    }

    enum ImGuiDragDropFlags{
        None = 0,
        SourceNoPreviewTooltip = 1,
        SourceNoDisableHover = 2,
        SourceNoHoldToOpenOthers = 4,
        SourceAllowNullID = 8,
        SourceExtern = 16,
        SourceAutoExpirePayload = 32,
        AcceptBeforeDelivery = 1024,
        AcceptNoDrawDefaultRect = 2048,
        AcceptNoPreviewTooltip = 4096,
        AcceptPeekOnly = 3072,
    }

    enum ImGuiLogType{
        None = 0,
        TTY = 1,
        File = 2,
        Buffer = 3,
        Clipboard = 4,
    }

    enum ImGuiNavForward{
        None = 0,
        ForwardQueued = 1,
        ForwardActive = 2,
    }

    enum ImGuiNavHighlightFlags{
        None = 0,
        TypeDefault = 1,
        TypeThin = 2,
        AlwaysDraw = 4,
        NoRounding = 8,
    }

    enum ImGuiTableFlags{
        None = 0,
        Resizable = 1,
        Reorderable = 2,
        Hideable = 4,
        Sortable = 8,
        NoSavedSettings = 16,
        ContextMenuInBody = 32,
        RowBg = 64,
        BordersInnerH = 128,
        BordersOuterH = 256,
        BordersInnerV = 512,
        BordersOuterV = 1024,
        BordersH = 384,
        BordersV = 1536,
        BordersInner = 640,
        BordersOuter = 1280,
        Borders = 1920,
        NoBordersInBody = 2048,
        NoBordersInBodyUntilResize = 4096,
        SizingFixedFit = 8192,
        SizingFixedSame = 16384,
        SizingStretchProp = 24576,
        SizingStretchSame = 32768,
        NoHostExtendX = 65536,
        NoHostExtendY = 131072,
        NoKeepColumnsVisible = 262144,
        PreciseWidths = 524288,
        NoClip = 1048576,
        PadOuterX = 2097152,
        NoPadOuterX = 4194304,
        NoPadInnerX = 8388608,
        ScrollX = 16777216,
        ScrollY = 33554432,
        SortMulti = 67108864,
        SortTristate = 134217728,
        SizingMask_ = 57344,
    }

    enum ImGuiTreeNodeFlagsPrivate{
        ImGuiTreeNodeFlags_ClipLabelForTrailingButton = 1048576,
    }

    enum ImDrawFlags{
        None = 0,
        Closed = 1,
        RoundCornersTopLeft = 16,
        RoundCornersTopRight = 32,
        RoundCornersBottomLeft = 64,
        RoundCornersBottomRight = 128,
        RoundCornersNone = 256,
        RoundCornersTop = 48,
        RoundCornersBottom = 192,
        RoundCornersLeft = 80,
        RoundCornersRight = 160,
        RoundCornersAll = 240,
        RoundCornersDefault_ = 240,
        RoundCornersMask_ = 496,
    }

    enum ImGuiFocusedFlags{
        None = 0,
        ChildWindows = 1,
        RootWindow = 2,
        AnyWindow = 4,
        RootAndChildWindows = 3,
    }

    enum ImGuiTabItemFlagsPrivate{
        ImGuiTabItemFlags_NoCloseButton = 1048576,
        ImGuiTabItemFlags_Button = 2097152,
    }

    enum ImGuiSliderFlags{
        None = 0,
        AlwaysClamp = 16,
        Logarithmic = 32,
        NoRoundToFormat = 64,
        NoInput = 128,
        InvalidMask_ = 1879048207,
    }

    enum ImGuiDataType{
        S8 = 0,
        U8 = 1,
        S16 = 2,
        U16 = 3,
        S32 = 4,
        U32 = 5,
        S64 = 6,
        U64 = 7,
        Float = 8,
        Double = 9,
        COUNT = 10,
    }

    enum ImGuiKey{
        Tab = 0,
        LeftArrow = 1,
        RightArrow = 2,
        UpArrow = 3,
        DownArrow = 4,
        PageUp = 5,
        PageDown = 6,
        Home = 7,
        End = 8,
        Insert = 9,
        Delete = 10,
        Backspace = 11,
        Space = 12,
        Enter = 13,
        Escape = 14,
        KeyPadEnter = 15,
        A = 16,
        C = 17,
        V = 18,
        X = 19,
        Y = 20,
        Z = 21,
        COUNT = 22,
    }

    enum ImGuiCol{
        Text = 0,
        TextDisabled = 1,
        WindowBg = 2,
        ChildBg = 3,
        PopupBg = 4,
        Border = 5,
        BorderShadow = 6,
        FrameBg = 7,
        FrameBgHovered = 8,
        FrameBgActive = 9,
        TitleBg = 10,
        TitleBgActive = 11,
        TitleBgCollapsed = 12,
        MenuBarBg = 13,
        ScrollbarBg = 14,
        ScrollbarGrab = 15,
        ScrollbarGrabHovered = 16,
        ScrollbarGrabActive = 17,
        CheckMark = 18,
        SliderGrab = 19,
        SliderGrabActive = 20,
        Button = 21,
        ButtonHovered = 22,
        ButtonActive = 23,
        Header = 24,
        HeaderHovered = 25,
        HeaderActive = 26,
        Separator = 27,
        SeparatorHovered = 28,
        SeparatorActive = 29,
        ResizeGrip = 30,
        ResizeGripHovered = 31,
        ResizeGripActive = 32,
        Tab = 33,
        TabHovered = 34,
        TabActive = 35,
        TabUnfocused = 36,
        TabUnfocusedActive = 37,
        PlotLines = 38,
        PlotLinesHovered = 39,
        PlotHistogram = 40,
        PlotHistogramHovered = 41,
        TableHeaderBg = 42,
        TableBorderStrong = 43,
        TableBorderLight = 44,
        TableRowBg = 45,
        TableRowBgAlt = 46,
        TextSelectedBg = 47,
        DragDropTarget = 48,
        NavHighlight = 49,
        NavWindowingHighlight = 50,
        NavWindowingDimBg = 51,
        ModalWindowDimBg = 52,
        COUNT = 53,
    }

    enum ImGuiButtonFlags{
        None = 0,
        MouseButtonLeft = 1,
        MouseButtonRight = 2,
        MouseButtonMiddle = 4,
        MouseButtonMask_ = 7,
        MouseButtonDefault_ = 1,
    }

    enum ImGuiViewportFlags{
        None = 0,
        IsPlatformWindow = 1,
        IsPlatformMonitor = 2,
        OwnedByApp = 4,
    }

    enum ImGuiSelectableFlagsPrivate{
        ImGuiSelectableFlags_NoHoldingActiveID = 1048576,
        ImGuiSelectableFlags_SelectOnClick = 2097152,
        ImGuiSelectableFlags_SelectOnRelease = 4194304,
        ImGuiSelectableFlags_SpanAvailWidth = 8388608,
        ImGuiSelectableFlags_DrawHoveredWhenHeld = 16777216,
        ImGuiSelectableFlags_SetNavIdOnHover = 33554432,
        ImGuiSelectableFlags_NoPadWithHalfSpacing = 67108864,
    }

    enum ImGuiInputSource{
        None = 0,
        Mouse = 1,
        Keyboard = 2,
        Gamepad = 3,
        Nav = 4,
        COUNT = 5,
    }

    enum ImGuiMouseCursor{
        None = -1,
        Arrow = 0,
        TextInput = 1,
        ResizeAll = 2,
        ResizeNS = 3,
        ResizeEW = 4,
        ResizeNESW = 5,
        ResizeNWSE = 6,
        Hand = 7,
        NotAllowed = 8,
        COUNT = 9,
    }

    enum ImGuiPlotType{
        Lines = 0,
        Histogram = 1,
    }

    enum ImGuiPopupFlags{
        None = 0,
        MouseButtonLeft = 0,
        MouseButtonRight = 1,
        MouseButtonMiddle = 2,
        MouseButtonMask_ = 31,
        MouseButtonDefault_ = 1,
        NoOpenOverExistingPopup = 32,
        NoOpenOverItems = 64,
        AnyPopupId = 128,
        AnyPopupLevel = 256,
        AnyPopup = 384,
    }

    enum ImGuiInputTextFlags{
        None = 0,
        CharsDecimal = 1,
        CharsHexadecimal = 2,
        CharsUppercase = 4,
        CharsNoBlank = 8,
        AutoSelectAll = 16,
        EnterReturnsTrue = 32,
        CallbackCompletion = 64,
        CallbackHistory = 128,
        CallbackAlways = 256,
        CallbackCharFilter = 512,
        AllowTabInput = 1024,
        CtrlEnterForNewLine = 2048,
        NoHorizontalScroll = 4096,
        AlwaysOverwrite = 8192,
        ReadOnly = 16384,
        Password = 32768,
        NoUndoRedo = 65536,
        CharsScientific = 131072,
        CallbackResize = 262144,
        CallbackEdit = 524288,
        Multiline = 1048576,
        NoMarkEdited = 2097152,
    }

    enum ImGuiOldColumnFlags{
        None = 0,
        NoBorder = 1,
        NoResize = 2,
        NoPreserveWidths = 4,
        NoForceWithinWindow = 8,
        GrowParentContentsSize = 16,
    }

    enum ImGuiSeparatorFlags{
        None = 0,
        Horizontal = 1,
        Vertical = 2,
        SpanAllColumns = 4,
    }

    enum ImGuiHoveredFlags{
        None = 0,
        ChildWindows = 1,
        RootWindow = 2,
        AnyWindow = 4,
        AllowWhenBlockedByPopup = 8,
        AllowWhenBlockedByActiveItem = 32,
        AllowWhenOverlapped = 64,
        AllowWhenDisabled = 128,
        RectOnly = 104,
        RootAndChildWindows = 3,
    }


    struct ImGuiSizeCallbackData {
        void* UserData;
        ImVec2 Pos;
        ImVec2 CurrentSize;
        ImVec2 DesiredSize;
    }

    struct ImGuiMetricsConfig {
        bool ShowWindowsRects;
        bool ShowWindowsBeginOrder;
        bool ShowTablesRects;
        bool ShowDrawCmdMesh;
        bool ShowDrawCmdBoundingBoxes;
        int ShowWindowsRectsType;
        int ShowTablesRectsType;
    }

    struct ImGuiShrinkWidthItem {
        int Index;
        float Width;
    }

    struct ImGuiStyleMod {
        ImGuiStyleVar VarIdx;
        union { int[2] BackupInt; float[2] BackupFloat;} ;
    }

    struct ImRect {
        ImVec2 Min;
        ImVec2 Max;
    }

    struct ImFontGlyphRangesBuilder {
        ImVector!(ImU32) UsedChars;
    }

    struct ImGuiDataTypeTempStorage {
        ImU8[8] Data;
    }

    struct ImGuiIO {
        ImGuiConfigFlags ConfigFlags;
        ImGuiBackendFlags BackendFlags;
        ImVec2 DisplaySize;
        float DeltaTime;
        float IniSavingRate;
        const(char)* IniFilename;
        const(char)* LogFilename;
        float MouseDoubleClickTime;
        float MouseDoubleClickMaxDist;
        float MouseDragThreshold;
        int[ImGuiKey.COUNT] KeyMap;
        float KeyRepeatDelay;
        float KeyRepeatRate;
        void* UserData;
        ImFontAtlas* Fonts;
        float FontGlobalScale;
        bool FontAllowUserScaling;
        ImFont* FontDefault;
        ImVec2 DisplayFramebufferScale;
        bool MouseDrawCursor;
        bool ConfigMacOSXBehaviors;
        bool ConfigInputTextCursorBlink;
        bool ConfigDragClickToInputText;
        bool ConfigWindowsResizeFromEdges;
        bool ConfigWindowsMoveFromTitleBarOnly;
        float ConfigMemoryCompactTimer;
        const(char)* BackendPlatformName;
        const(char)* BackendRendererName;
        void* BackendPlatformUserData;
        void* BackendRendererUserData;
        void* BackendLanguageUserData;
        const(char)* function(void* user_data) GetClipboardTextFn;
        void function(void* user_data,const(char)* text) SetClipboardTextFn;
        void* ClipboardUserData;
        void function(int x,int y) ImeSetInputScreenPosFn;
        void* ImeWindowHandle;
        ImVec2 MousePos;
        bool[5] MouseDown;
        float MouseWheel;
        float MouseWheelH;
        bool KeyCtrl;
        bool KeyShift;
        bool KeyAlt;
        bool KeySuper;
        bool[512] KeysDown;
        float[ImGuiNavInput.COUNT] NavInputs;
        bool WantCaptureMouse;
        bool WantCaptureKeyboard;
        bool WantTextInput;
        bool WantSetMousePos;
        bool WantSaveIniSettings;
        bool NavActive;
        bool NavVisible;
        float Framerate;
        int MetricsRenderVertices;
        int MetricsRenderIndices;
        int MetricsRenderWindows;
        int MetricsActiveWindows;
        int MetricsActiveAllocations;
        ImVec2 MouseDelta;
        ImGuiKeyModFlags KeyMods;
        ImVec2 MousePosPrev;
        ImVec2[5] MouseClickedPos;
        double[5] MouseClickedTime;
        bool[5] MouseClicked;
        bool[5] MouseDoubleClicked;
        bool[5] MouseReleased;
        bool[5] MouseDownOwned;
        bool[5] MouseDownWasDoubleClick;
        float[5] MouseDownDuration;
        float[5] MouseDownDurationPrev;
        ImVec2[5] MouseDragMaxDistanceAbs;
        float[5] MouseDragMaxDistanceSqr;
        float[512] KeysDownDuration;
        float[512] KeysDownDurationPrev;
        float[ImGuiNavInput.COUNT] NavInputsDownDuration;
        float[ImGuiNavInput.COUNT] NavInputsDownDurationPrev;
        float PenPressure;
        ImWchar16 InputQueueSurrogate;
        ImVector!(ImWchar) InputQueueCharacters;
    }

    struct ImGuiTextFilter {
        char[256] InputBuf;
        ImVector!(ImGuiTextRange) Filters;
        int CountGrep;
    }

    struct ImGuiDataTypeInfo {
        size_t Size;
        const(char)* Name;
        const(char)* PrintFmt;
        const(char)* ScanFmt;
    }

    struct ImFontAtlasCustomRect {
        ushort Width;
        ushort Height;
        ushort X;
        ushort Y;
        uint GlyphID;
        float GlyphAdvanceX;
        ImVec2 GlyphOffset;
        ImFont* Font;
    }

    struct ImGuiPopupData {
        ImGuiID PopupId;
        ImGuiWindow* Window;
        ImGuiWindow* SourceWindow;
        int OpenFrameCount;
        ImGuiID OpenParentId;
        ImVec2 OpenPopupPos;
        ImVec2 OpenMousePos;
    }

    struct ImGuiWindow {
        char* Name;
        ImGuiID ID;
        ImGuiWindowFlags Flags;
        ImVec2 Pos;
        ImVec2 Size;
        ImVec2 SizeFull;
        ImVec2 ContentSize;
        ImVec2 ContentSizeIdeal;
        ImVec2 ContentSizeExplicit;
        ImVec2 WindowPadding;
        float WindowRounding;
        float WindowBorderSize;
        int NameBufLen;
        ImGuiID MoveId;
        ImGuiID ChildId;
        ImVec2 Scroll;
        ImVec2 ScrollMax;
        ImVec2 ScrollTarget;
        ImVec2 ScrollTargetCenterRatio;
        ImVec2 ScrollTargetEdgeSnapDist;
        ImVec2 ScrollbarSizes;
        bool ScrollbarX;
        bool ScrollbarY;
        bool Active;
        bool WasActive;
        bool WriteAccessed;
        bool Collapsed;
        bool WantCollapseToggle;
        bool SkipItems;
        bool Appearing;
        bool Hidden;
        bool IsFallbackWindow;
        bool HasCloseButton;
        byte ResizeBorderHeld;
        short BeginCount;
        short BeginOrderWithinParent;
        short BeginOrderWithinContext;
        ImGuiID PopupId;
        ImS8 AutoFitFramesX;
        ImS8 AutoFitFramesY;
        ImS8 AutoFitChildAxises;
        bool AutoFitOnlyGrows;
        ImGuiDir AutoPosLastDirection;
        ImS8 HiddenFramesCanSkipItems;
        ImS8 HiddenFramesCannotSkipItems;
        ImS8 HiddenFramesForRenderOnly;
        ImGuiCond SetWindowPosAllowFlags;
        ImGuiCond SetWindowSizeAllowFlags;
        ImGuiCond SetWindowCollapsedAllowFlags;
        ImVec2 SetWindowPosVal;
        ImVec2 SetWindowPosPivot;
        ImVector!(ImGuiID) IDStack;
        ImGuiWindowTempData DC;
        ImRect OuterRectClipped;
        ImRect InnerRect;
        ImRect InnerClipRect;
        ImRect WorkRect;
        ImRect ParentWorkRect;
        ImRect ClipRect;
        ImRect ContentRegionRect;
        ImVec2ih HitTestHoleSize;
        ImVec2ih HitTestHoleOffset;
        int LastFrameActive;
        float LastTimeActive;
        float ItemWidthDefault;
        ImGuiStorage StateStorage;
        ImVector!(ImGuiOldColumns) ColumnsStorage;
        float FontWindowScale;
        int SettingsOffset;
        ImDrawList* DrawList;
        ImDrawList DrawListInst;
        ImGuiWindow* ParentWindow;
        ImGuiWindow* RootWindow;
        ImGuiWindow* RootWindowForTitleBarHighlight;
        ImGuiWindow* RootWindowForNav;
        ImGuiWindow* NavLastChildNavWindow;
        ImGuiID[ImGuiNavLayer.COUNT] NavLastIds;
        ImRect[ImGuiNavLayer.COUNT] NavRectRel;
        int MemoryDrawListIdxCapacity;
        int MemoryDrawListVtxCapacity;
        bool MemoryCompacted;
    }

    struct ImGuiTabBar {
        ImVector!(ImGuiTabItem) Tabs;
        ImGuiTabBarFlags Flags;
        ImGuiID ID;
        ImGuiID SelectedTabId;
        ImGuiID NextSelectedTabId;
        ImGuiID VisibleTabId;
        int CurrFrameVisible;
        int PrevFrameVisible;
        ImRect BarRect;
        float CurrTabsContentsHeight;
        float PrevTabsContentsHeight;
        float WidthAllTabs;
        float WidthAllTabsIdeal;
        float ScrollingAnim;
        float ScrollingTarget;
        float ScrollingTargetDistToVisibility;
        float ScrollingSpeed;
        float ScrollingRectMinX;
        float ScrollingRectMaxX;
        ImGuiID ReorderRequestTabId;
        ImS8 ReorderRequestDir;
        ImS8 BeginCount;
        bool WantLayout;
        bool VisibleTabWasSubmitted;
        bool TabsAddedNew;
        ImS16 TabsActiveCount;
        ImS16 LastTabItemIdx;
        float ItemSpacingY;
        ImVec2 FramePadding;
        ImVec2 BackupCursorPos;
        ImGuiTextBuffer TabsNames;
    }

    struct ImGuiViewport {
        ImGuiViewportFlags Flags;
        ImVec2 Pos;
        ImVec2 Size;
        ImVec2 WorkPos;
        ImVec2 WorkSize;
    }

    struct ImVec2 {
        float x;
        float y;
    }

    struct ImGuiPayload {
        void* Data;
        int DataSize;
        ImGuiID SourceId;
        ImGuiID SourceParentId;
        int DataFrameCount;
        char[32+1] DataType;
        bool Preview;
        bool Delivery;
    }

    struct ImBitVector {
        ImVector!(ImU32) Storage;
    }

    struct ImDrawVert {
        ImVec2 pos;
        ImVec2 uv;
        ImU32 col;
    }

    struct ImGuiOldColumnData {
        float OffsetNorm;
        float OffsetNormBeforeResize;
        ImGuiOldColumnFlags Flags;
        ImRect ClipRect;
    }

    struct ImGuiTableSettings {
        ImGuiID ID;
        ImGuiTableFlags SaveFlags;
        float RefScale;
        ImGuiTableColumnIdx ColumnsCount;
        ImGuiTableColumnIdx ColumnsCountMax;
        bool WantApply;
    }

    struct ImGuiTable {
        ImGuiID ID;
        ImGuiTableFlags Flags;
        void* RawData;
        ImSpan!(ImGuiTableColumn) Columns;
        ImSpan!(ImGuiTableColumnIdx) DisplayOrderToIndex;
        ImSpan!(ImGuiTableCellData) RowCellData;
        ImU64 EnabledMaskByDisplayOrder;
        ImU64 EnabledMaskByIndex;
        ImU64 VisibleMaskByIndex;
        ImU64 RequestOutputMaskByIndex;
        ImGuiTableFlags SettingsLoadedFlags;
        int SettingsOffset;
        int LastFrameActive;
        int ColumnsCount;
        int CurrentRow;
        int CurrentColumn;
        ImS16 InstanceCurrent;
        ImS16 InstanceInteracted;
        float RowPosY1;
        float RowPosY2;
        float RowMinHeight;
        float RowTextBaseline;
        float RowIndentOffsetX;
        ImGuiTableRowFlags RowFlags;
        ImGuiTableRowFlags LastRowFlags;
        int RowBgColorCounter;
        ImU32[2] RowBgColor;
        ImU32 BorderColorStrong;
        ImU32 BorderColorLight;
        float BorderX1;
        float BorderX2;
        float HostIndentX;
        float MinColumnWidth;
        float OuterPaddingX;
        float CellPaddingX;
        float CellPaddingY;
        float CellSpacingX1;
        float CellSpacingX2;
        float LastOuterHeight;
        float LastFirstRowHeight;
        float InnerWidth;
        float ColumnsGivenWidth;
        float ColumnsAutoFitWidth;
        float ResizedColumnNextWidth;
        float ResizeLockMinContentsX2;
        float RefScale;
        ImRect OuterRect;
        ImRect InnerRect;
        ImRect WorkRect;
        ImRect InnerClipRect;
        ImRect BgClipRect;
        ImRect Bg0ClipRectForDrawCmd;
        ImRect Bg2ClipRectForDrawCmd;
        ImRect HostClipRect;
        ImRect HostBackupWorkRect;
        ImRect HostBackupParentWorkRect;
        ImRect HostBackupInnerClipRect;
        ImVec2 HostBackupPrevLineSize;
        ImVec2 HostBackupCurrLineSize;
        ImVec2 HostBackupCursorMaxPos;
        ImVec2 UserOuterSize;
        ImVec1 HostBackupColumnsOffset;
        float HostBackupItemWidth;
        int HostBackupItemWidthStackSize;
        ImGuiWindow* OuterWindow;
        ImGuiWindow* InnerWindow;
        ImGuiTextBuffer ColumnsNames;
        ImDrawListSplitter DrawSplitter;
        ImGuiTableColumnSortSpecs SortSpecsSingle;
        ImVector!(ImGuiTableColumnSortSpecs) SortSpecsMulti;
        ImGuiTableSortSpecs SortSpecs;
        ImGuiTableColumnIdx SortSpecsCount;
        ImGuiTableColumnIdx ColumnsEnabledCount;
        ImGuiTableColumnIdx ColumnsEnabledFixedCount;
        ImGuiTableColumnIdx DeclColumnsCount;
        ImGuiTableColumnIdx HoveredColumnBody;
        ImGuiTableColumnIdx HoveredColumnBorder;
        ImGuiTableColumnIdx AutoFitSingleColumn;
        ImGuiTableColumnIdx ResizedColumn;
        ImGuiTableColumnIdx LastResizedColumn;
        ImGuiTableColumnIdx HeldHeaderColumn;
        ImGuiTableColumnIdx ReorderColumn;
        ImGuiTableColumnIdx ReorderColumnDir;
        ImGuiTableColumnIdx LeftMostEnabledColumn;
        ImGuiTableColumnIdx RightMostEnabledColumn;
        ImGuiTableColumnIdx LeftMostStretchedColumn;
        ImGuiTableColumnIdx RightMostStretchedColumn;
        ImGuiTableColumnIdx ContextPopupColumn;
        ImGuiTableColumnIdx FreezeRowsRequest;
        ImGuiTableColumnIdx FreezeRowsCount;
        ImGuiTableColumnIdx FreezeColumnsRequest;
        ImGuiTableColumnIdx FreezeColumnsCount;
        ImGuiTableColumnIdx RowCellDataCurrent;
        ImGuiTableDrawChannelIdx DummyDrawChannel;
        ImGuiTableDrawChannelIdx Bg2DrawChannelCurrent;
        ImGuiTableDrawChannelIdx Bg2DrawChannelUnfrozen;
        bool IsLayoutLocked;
        bool IsInsideRow;
        bool IsInitializing;
        bool IsSortSpecsDirty;
        bool IsUsingHeaders;
        bool IsContextPopupOpen;
        bool IsSettingsRequestLoad;
        bool IsSettingsDirty;
        bool IsDefaultDisplayOrder;
        bool IsResetAllRequest;
        bool IsResetDisplayOrderRequest;
        bool IsUnfrozenRows;
        bool IsDefaultSizingPolicy;
        bool MemoryCompacted;
        bool HostSkipItems;
    }

    struct StbTexteditRow {
        float x0;
        float x1;
        float baseline_y_delta;
        float ymin;
        float ymax;
        int num_chars;
    }

    struct ImGuiWindowTempData {
        ImVec2 CursorPos;
        ImVec2 CursorPosPrevLine;
        ImVec2 CursorStartPos;
        ImVec2 CursorMaxPos;
        ImVec2 IdealMaxPos;
        ImVec2 CurrLineSize;
        ImVec2 PrevLineSize;
        float CurrLineTextBaseOffset;
        float PrevLineTextBaseOffset;
        ImVec1 Indent;
        ImVec1 ColumnsOffset;
        ImVec1 GroupOffset;
        ImGuiID LastItemId;
        ImGuiItemStatusFlags LastItemStatusFlags;
        ImRect LastItemRect;
        ImRect LastItemDisplayRect;
        ImGuiNavLayer NavLayerCurrent;
        int NavLayerActiveMask;
        int NavLayerActiveMaskNext;
        ImGuiID NavFocusScopeIdCurrent;
        bool NavHideHighlightOneFrame;
        bool NavHasScroll;
        bool MenuBarAppending;
        ImVec2 MenuBarOffset;
        ImGuiMenuColumns MenuColumns;
        int TreeDepth;
        ImU32 TreeJumpToParentOnPopMask;
        ImVector!(ImGuiWindow*) ChildWindows;
        ImGuiStorage* StateStorage;
        ImGuiOldColumns* CurrentColumns;
        int CurrentTableIdx;
        ImGuiLayoutType LayoutType;
        ImGuiLayoutType ParentLayoutType;
        int FocusCounterRegular;
        int FocusCounterTabStop;
        ImGuiItemFlags ItemFlags;
        float ItemWidth;
        float TextWrapPos;
        ImVector!(float) ItemWidthStack;
        ImVector!(float) TextWrapPosStack;
        ImGuiStackSizes StackSizesOnBegin;
    }

    struct StbUndoRecord {
        int where;
        int insert_length;
        int delete_length;
        int char_storage;
    }

    struct ImGuiGroupData {
        ImGuiID WindowID;
        ImVec2 BackupCursorPos;
        ImVec2 BackupCursorMaxPos;
        ImVec1 BackupIndent;
        ImVec1 BackupGroupOffset;
        ImVec2 BackupCurrLineSize;
        float BackupCurrLineTextBaseOffset;
        ImGuiID BackupActiveIdIsAlive;
        bool BackupActiveIdPreviousFrameIsAlive;
        bool BackupHoveredIdIsAlive;
        bool EmitItem;
    }

    struct ImGuiColorMod {
        ImGuiCol Col;
        ImVec4 BackupValue;
    }

    struct ImColor {
        ImVec4 Value;
    }

    struct ImGuiInputTextCallbackData {
        ImGuiInputTextFlags EventFlag;
        ImGuiInputTextFlags Flags;
        void* UserData;
        ImWchar EventChar;
        ImGuiKey EventKey;
        char* Buf;
        int BufTextLen;
        int BufSize;
        bool BufDirty;
        int CursorPos;
        int SelectionStart;
        int SelectionEnd;
    }

    struct ImGuiOldColumns {
        ImGuiID ID;
        ImGuiOldColumnFlags Flags;
        bool IsFirstFrame;
        bool IsBeingResized;
        int Current;
        int Count;
        float OffMinX;
        float OffMaxX;
        float LineMinY;
        float LineMaxY;
        float HostCursorPosY;
        float HostCursorMaxPosX;
        ImRect HostInitialClipRect;
        ImRect HostBackupClipRect;
        ImRect HostBackupParentWorkRect;
        ImVector!(ImGuiOldColumnData) Columns;
        ImDrawListSplitter Splitter;
    }

    struct ImFontGlyph {
        uint Colored;
        uint Visible;
        uint Codepoint;
        float AdvanceX;
        float X0;
        float Y0;
        float X1;
        float Y1;
        float U0;
        float V0;
        float U1;
        float V1;
    }

    struct ImGuiNextItemData {
        ImGuiNextItemDataFlags Flags;
        float Width;
        ImGuiID FocusScopeId;
        ImGuiCond OpenCond;
        bool OpenVal;
    }

    struct ImFontAtlas {
        ImFontAtlasFlags Flags;
        ImTextureID TexID;
        int TexDesiredWidth;
        int TexGlyphPadding;
        bool Locked;
        bool TexPixelsUseColors;
        char* TexPixelsAlpha8;
        uint* TexPixelsRGBA32;
        int TexWidth;
        int TexHeight;
        ImVec2 TexUvScale;
        ImVec2 TexUvWhitePixel;
        ImVector!(ImFont*) Fonts;
        ImVector!(ImFontAtlasCustomRect) CustomRects;
        ImVector!(ImFontConfig) ConfigData;
        ImVec4[(63)+1] TexUvLines;
        const ImFontBuilderIO* FontBuilderIO;
        uint FontBuilderFlags;
        int PackIdMouseCursors;
        int PackIdLines;
    }

    struct ImGuiStyle {
        float Alpha;
        ImVec2 WindowPadding;
        float WindowRounding;
        float WindowBorderSize;
        ImVec2 WindowMinSize;
        ImVec2 WindowTitleAlign;
        ImGuiDir WindowMenuButtonPosition;
        float ChildRounding;
        float ChildBorderSize;
        float PopupRounding;
        float PopupBorderSize;
        ImVec2 FramePadding;
        float FrameRounding;
        float FrameBorderSize;
        ImVec2 ItemSpacing;
        ImVec2 ItemInnerSpacing;
        ImVec2 CellPadding;
        ImVec2 TouchExtraPadding;
        float IndentSpacing;
        float ColumnsMinSpacing;
        float ScrollbarSize;
        float ScrollbarRounding;
        float GrabMinSize;
        float GrabRounding;
        float LogSliderDeadzone;
        float TabRounding;
        float TabBorderSize;
        float TabMinWidthForCloseButton;
        ImGuiDir ColorButtonPosition;
        ImVec2 ButtonTextAlign;
        ImVec2 SelectableTextAlign;
        ImVec2 DisplayWindowPadding;
        ImVec2 DisplaySafeAreaPadding;
        float MouseCursorScale;
        bool AntiAliasedLines;
        bool AntiAliasedLinesUseTex;
        bool AntiAliasedFill;
        float CurveTessellationTol;
        float CircleTessellationMaxError;
        ImVec4[ImGuiCol.COUNT] Colors;
    }

    struct ImGuiTableCellData {
        ImU32 BgColor;
        ImGuiTableColumnIdx Column;
    }

    struct ImGuiTextRange {
        const(char)* b;
        const(char)* e;
    }

    struct ImGuiContext {
        bool Initialized;
        bool FontAtlasOwnedByContext;
        ImGuiIO IO;
        ImGuiStyle Style;
        ImFont* Font;
        float FontSize;
        float FontBaseSize;
        ImDrawListSharedData DrawListSharedData;
        double Time;
        int FrameCount;
        int FrameCountEnded;
        int FrameCountRendered;
        bool WithinFrameScope;
        bool WithinFrameScopeWithImplicitWindow;
        bool WithinEndChild;
        bool GcCompactAll;
        bool TestEngineHookItems;
        ImGuiID TestEngineHookIdInfo;
        void* TestEngine;
        ImVector!(ImGuiWindow*) Windows;
        ImVector!(ImGuiWindow*) WindowsFocusOrder;
        ImVector!(ImGuiWindow*) WindowsTempSortBuffer;
        ImVector!(ImGuiWindow*) CurrentWindowStack;
        ImGuiStorage WindowsById;
        int WindowsActiveCount;
        ImGuiWindow* CurrentWindow;
        ImGuiWindow* HoveredWindow;
        ImGuiWindow* HoveredWindowUnderMovingWindow;
        ImGuiWindow* MovingWindow;
        ImGuiWindow* WheelingWindow;
        ImVec2 WheelingWindowRefMousePos;
        float WheelingWindowTimer;
        ImGuiID HoveredId;
        ImGuiID HoveredIdPreviousFrame;
        bool HoveredIdAllowOverlap;
        bool HoveredIdUsingMouseWheel;
        bool HoveredIdPreviousFrameUsingMouseWheel;
        bool HoveredIdDisabled;
        float HoveredIdTimer;
        float HoveredIdNotActiveTimer;
        ImGuiID ActiveId;
        ImGuiID ActiveIdIsAlive;
        float ActiveIdTimer;
        bool ActiveIdIsJustActivated;
        bool ActiveIdAllowOverlap;
        bool ActiveIdNoClearOnFocusLoss;
        bool ActiveIdHasBeenPressedBefore;
        bool ActiveIdHasBeenEditedBefore;
        bool ActiveIdHasBeenEditedThisFrame;
        bool ActiveIdUsingMouseWheel;
        ImU32 ActiveIdUsingNavDirMask;
        ImU32 ActiveIdUsingNavInputMask;
        ImU64 ActiveIdUsingKeyInputMask;
        ImVec2 ActiveIdClickOffset;
        ImGuiWindow* ActiveIdWindow;
        ImGuiInputSource ActiveIdSource;
        int ActiveIdMouseButton;
        ImGuiID ActiveIdPreviousFrame;
        bool ActiveIdPreviousFrameIsAlive;
        bool ActiveIdPreviousFrameHasBeenEditedBefore;
        ImGuiWindow* ActiveIdPreviousFrameWindow;
        ImGuiID LastActiveId;
        float LastActiveIdTimer;
        ImGuiNextWindowData NextWindowData;
        ImGuiNextItemData NextItemData;
        ImVector!(ImGuiColorMod) ColorStack;
        ImVector!(ImGuiStyleMod) StyleVarStack;
        ImVector!(ImFont*) FontStack;
        ImVector!(ImGuiID) FocusScopeStack;
        ImVector!(ImGuiItemFlags) ItemFlagsStack;
        ImVector!(ImGuiGroupData) GroupStack;
        ImVector!(ImGuiPopupData) OpenPopupStack;
        ImVector!(ImGuiPopupData) BeginPopupStack;
        ImVector!(ImGuiViewportP*) Viewports;
        ImGuiWindow* NavWindow;
        ImGuiID NavId;
        ImGuiID NavFocusScopeId;
        ImGuiID NavActivateId;
        ImGuiID NavActivateDownId;
        ImGuiID NavActivatePressedId;
        ImGuiID NavInputId;
        ImGuiID NavJustTabbedId;
        ImGuiID NavJustMovedToId;
        ImGuiID NavJustMovedToFocusScopeId;
        ImGuiKeyModFlags NavJustMovedToKeyMods;
        ImGuiID NavNextActivateId;
        ImGuiInputSource NavInputSource;
        ImRect NavScoringRect;
        int NavScoringCount;
        ImGuiNavLayer NavLayer;
        int NavIdTabCounter;
        bool NavIdIsAlive;
        bool NavMousePosDirty;
        bool NavDisableHighlight;
        bool NavDisableMouseHover;
        bool NavAnyRequest;
        bool NavInitRequest;
        bool NavInitRequestFromMove;
        ImGuiID NavInitResultId;
        ImRect NavInitResultRectRel;
        bool NavMoveRequest;
        ImGuiNavMoveFlags NavMoveRequestFlags;
        ImGuiNavForward NavMoveRequestForward;
        ImGuiKeyModFlags NavMoveRequestKeyMods;
        ImGuiDir NavMoveDir;
        ImGuiDir NavMoveDirLast;
        ImGuiDir NavMoveClipDir;
        ImGuiNavMoveResult NavMoveResultLocal;
        ImGuiNavMoveResult NavMoveResultLocalVisibleSet;
        ImGuiNavMoveResult NavMoveResultOther;
        ImGuiWindow* NavWrapRequestWindow;
        ImGuiNavMoveFlags NavWrapRequestFlags;
        ImGuiWindow* NavWindowingTarget;
        ImGuiWindow* NavWindowingTargetAnim;
        ImGuiWindow* NavWindowingListWindow;
        float NavWindowingTimer;
        float NavWindowingHighlightAlpha;
        bool NavWindowingToggleLayer;
        ImGuiWindow* TabFocusRequestCurrWindow;
        ImGuiWindow* TabFocusRequestNextWindow;
        int TabFocusRequestCurrCounterRegular;
        int TabFocusRequestCurrCounterTabStop;
        int TabFocusRequestNextCounterRegular;
        int TabFocusRequestNextCounterTabStop;
        bool TabFocusPressed;
        float DimBgRatio;
        ImGuiMouseCursor MouseCursor;
        bool DragDropActive;
        bool DragDropWithinSource;
        bool DragDropWithinTarget;
        ImGuiDragDropFlags DragDropSourceFlags;
        int DragDropSourceFrameCount;
        int DragDropMouseButton;
        ImGuiPayload DragDropPayload;
        ImRect DragDropTargetRect;
        ImGuiID DragDropTargetId;
        ImGuiDragDropFlags DragDropAcceptFlags;
        float DragDropAcceptIdCurrRectSurface;
        ImGuiID DragDropAcceptIdCurr;
        ImGuiID DragDropAcceptIdPrev;
        int DragDropAcceptFrameCount;
        ImGuiID DragDropHoldJustPressedId;
        ImVector!(char) DragDropPayloadBufHeap;
        char[16] DragDropPayloadBufLocal;
        ImGuiTable* CurrentTable;
        ImPool_ImGuiTable Tables;
        ImVector!(ImGuiPtrOrIndex) CurrentTableStack;
        ImVector!(float) TablesLastTimeActive;
        ImVector!(ImDrawChannel) DrawChannelsTempMergeBuffer;
        ImGuiTabBar* CurrentTabBar;
        ImPool_ImGuiTabBar TabBars;
        ImVector!(ImGuiPtrOrIndex) CurrentTabBarStack;
        ImVector!(ImGuiShrinkWidthItem) ShrinkWidthBuffer;
        ImVec2 LastValidMousePos;
        ImGuiInputTextState InputTextState;
        ImFont InputTextPasswordFont;
        ImGuiID TempInputId;
        ImGuiColorEditFlags ColorEditOptions;
        float ColorEditLastHue;
        float ColorEditLastSat;
        float[3] ColorEditLastColor;
        ImVec4 ColorPickerRef;
        float SliderCurrentAccum;
        bool SliderCurrentAccumDirty;
        bool DragCurrentAccumDirty;
        float DragCurrentAccum;
        float DragSpeedDefaultRatio;
        float ScrollbarClickDeltaToGrabCenter;
        int TooltipOverrideCount;
        float TooltipSlowDelay;
        ImVector!(char) ClipboardHandlerData;
        ImVector!(ImGuiID) MenusIdSubmittedThisFrame;
        ImVec2 PlatformImePos;
        ImVec2 PlatformImeLastPos;
        char PlatformLocaleDecimalPoint;
        bool SettingsLoaded;
        float SettingsDirtyTimer;
        ImGuiTextBuffer SettingsIniData;
        ImVector!(ImGuiSettingsHandler) SettingsHandlers;
        ImChunkStream_ImGuiWindowSettings SettingsWindows;
        ImChunkStream_ImGuiTableSettings SettingsTables;
        ImVector!(ImGuiContextHook) Hooks;
        ImGuiID HookIdNext;
        bool LogEnabled;
        ImGuiLogType LogType;
        ImFileHandle LogFile;
        ImGuiTextBuffer LogBuffer;
        const(char)* LogNextPrefix;
        const(char)* LogNextSuffix;
        float LogLinePosY;
        bool LogLineFirstItem;
        int LogDepthRef;
        int LogDepthToExpand;
        int LogDepthToExpandDefault;
        bool DebugItemPickerActive;
        ImGuiID DebugItemPickerBreakId;
        ImGuiMetricsConfig DebugMetricsConfig;
        float[120] FramerateSecPerFrame;
        int FramerateSecPerFrameIdx;
        float FramerateSecPerFrameAccum;
        int WantCaptureMouseNextFrame;
        int WantCaptureKeyboardNextFrame;
        int WantTextInputNextFrame;
        char[1024*3+1] TempBuffer;
    }

    struct ImGuiTableColumn {
        ImGuiTableColumnFlags Flags;
        float WidthGiven;
        float MinX;
        float MaxX;
        float WidthRequest;
        float WidthAuto;
        float StretchWeight;
        float InitStretchWeightOrWidth;
        ImRect ClipRect;
        ImGuiID UserID;
        float WorkMinX;
        float WorkMaxX;
        float ItemWidth;
        float ContentMaxXFrozen;
        float ContentMaxXUnfrozen;
        float ContentMaxXHeadersUsed;
        float ContentMaxXHeadersIdeal;
        ImS16 NameOffset;
        ImGuiTableColumnIdx DisplayOrder;
        ImGuiTableColumnIdx IndexWithinEnabledSet;
        ImGuiTableColumnIdx PrevEnabledColumn;
        ImGuiTableColumnIdx NextEnabledColumn;
        ImGuiTableColumnIdx SortOrder;
        ImGuiTableDrawChannelIdx DrawChannelCurrent;
        ImGuiTableDrawChannelIdx DrawChannelFrozen;
        ImGuiTableDrawChannelIdx DrawChannelUnfrozen;
        bool IsEnabled;
        bool IsEnabledNextFrame;
        bool IsVisibleX;
        bool IsVisibleY;
        bool IsRequestOutput;
        bool IsSkipItems;
        bool IsPreserveWidthAuto;
        ImS8 NavLayerCurrent;
        ImU8 AutoFitQueue;
        ImU8 CannotSkipItemsQueue;
        ImU8 SortDirection;
        ImU8 SortDirectionsAvailCount;
        ImU8 SortDirectionsAvailMask;
        ImU8 SortDirectionsAvailList;
    }

    struct ImFontConfig {
        void* FontData;
        int FontDataSize;
        bool FontDataOwnedByAtlas;
        int FontNo;
        float SizePixels;
        int OversampleH;
        int OversampleV;
        bool PixelSnapH;
        ImVec2 GlyphExtraSpacing;
        ImVec2 GlyphOffset;
        const ImWchar* GlyphRanges;
        float GlyphMinAdvanceX;
        float GlyphMaxAdvanceX;
        bool MergeMode;
        uint FontBuilderFlags;
        float RasterizerMultiply;
        ImWchar EllipsisChar;
        char[40] Name;
        ImFont* DstFont;
    }

    struct ImDrawCmdHeader {
        ImVec4 ClipRect;
        ImTextureID TextureId;
        uint VtxOffset;
    }

    struct ImDrawListSharedData {
        ImVec2 TexUvWhitePixel;
        ImFont* Font;
        float FontSize;
        float CurveTessellationTol;
        float CircleSegmentMaxError;
        ImVec4 ClipRectFullscreen;
        ImDrawListFlags InitialFlags;
        ImVec2[48] ArcFastVtx;
        float ArcFastRadiusCutoff;
        ImU8[64] CircleSegmentCounts;
        const ImVec4* TexUvLines;
    }

    struct ImDrawDataBuilder {
        ImVector!(ImDrawList*)[2] Layers;
    }

    struct ImGuiTableSortSpecs {
        const ImGuiTableColumnSortSpecs* Specs;
        int SpecsCount;
        bool SpecsDirty;
    }

    struct ImVec1 {
        float x;
    }

    struct ImGuiViewportP {
        ImGuiViewport _ImGuiViewport;
        int[2] DrawListsLastFrame;
        ImDrawList*[2] DrawLists;
        ImDrawData DrawDataP;
        ImDrawDataBuilder DrawDataBuilder;
        ImVec2 WorkOffsetMin;
        ImVec2 WorkOffsetMax;
        ImVec2 CurrWorkOffsetMin;
        ImVec2 CurrWorkOffsetMax;
    }

    struct ImDrawData {
        bool Valid;
        int CmdListsCount;
        int TotalIdxCount;
        int TotalVtxCount;
        ImDrawList** CmdLists;
        ImVec2 DisplayPos;
        ImVec2 DisplaySize;
        ImVec2 FramebufferScale;
    }

    struct ImGuiInputTextState {
        ImGuiID ID;
        int CurLenW;
        int CurLenA;
        ImVector!(ImWchar) TextW;
        ImVector!(char) TextA;
        ImVector!(char) InitialTextA;
        bool TextAIsValid;
        int BufCapacityA;
        float ScrollX;
        STB_TexteditState Stb;
        float CursorAnim;
        bool CursorFollow;
        bool SelectedAllMouseLock;
        bool Edited;
        ImGuiInputTextFlags UserFlags;
        ImGuiInputTextCallback UserCallback;
        void* UserCallbackData;
    }

    struct ImGuiPtrOrIndex {
        void* Ptr;
        int Index;
    }

    struct ImGuiTableColumnSortSpecs {
        ImGuiID ColumnUserID;
        ImS16 ColumnIndex;
        ImS16 SortOrder;
        ImGuiSortDirection SortDirection;
    }

    struct ImFont {
        ImVector!(float) IndexAdvanceX;
        float FallbackAdvanceX;
        float FontSize;
        ImVector!(ImWchar) IndexLookup;
        ImVector!(ImFontGlyph) Glyphs;
        const ImFontGlyph* FallbackGlyph;
        ImFontAtlas* ContainerAtlas;
        const ImFontConfig* ConfigData;
        short ConfigDataCount;
        ImWchar FallbackChar;
        ImWchar EllipsisChar;
        bool DirtyLookupTables;
        float Scale;
        float Ascent;
        float Descent;
        int MetricsTotalSurface;
        ImU8[(0xFFFF+1)/4096/8] Used4kPagesMap;
    }

    struct ImGuiOnceUponAFrame {
        int RefFrame;
    }

    struct ImGuiWindowSettings {
        ImGuiID ID;
        ImVec2ih Pos;
        ImVec2ih Size;
        bool Collapsed;
        bool WantApply;
    }

    struct ImGuiStackSizes {
        short SizeOfIDStack;
        short SizeOfColorStack;
        short SizeOfStyleVarStack;
        short SizeOfFontStack;
        short SizeOfFocusScopeStack;
        short SizeOfGroupStack;
        short SizeOfBeginPopupStack;
    }

    struct ImVec4 {
        float x;
        float y;
        float z;
        float w;
    }

    struct ImGuiNavMoveResult {
        ImGuiWindow* Window;
        ImGuiID ID;
        ImGuiID FocusScopeId;
        float DistBox;
        float DistCenter;
        float DistAxial;
        ImRect RectRel;
    }

    struct ImGuiSettingsHandler {
        const(char)* TypeName;
        ImGuiID TypeHash;
        void function(ImGuiContext* ctx,ImGuiSettingsHandler* handler) ClearAllFn;
        void function(ImGuiContext* ctx,ImGuiSettingsHandler* handler) ReadInitFn;
        void* function(ImGuiContext* ctx,ImGuiSettingsHandler* handler,const(char)* name) ReadOpenFn;
        void function(ImGuiContext* ctx,ImGuiSettingsHandler* handler,void* entry,const(char)* line) ReadLineFn;
        void function(ImGuiContext* ctx,ImGuiSettingsHandler* handler) ApplyAllFn;
        void function(ImGuiContext* ctx,ImGuiSettingsHandler* handler,ImGuiTextBuffer* out_buf) WriteAllFn;
        void* UserData;
    }

    struct ImDrawListSplitter {
        int _Current;
        int _Count;
        ImVector!(ImDrawChannel) _Channels;
    }

    struct STB_TexteditState {
        int cursor;
        int select_start;
        int select_end;
        char insert_mode;
        int row_count_per_page;
        char cursor_at_end_of_line;
        char initialized;
        char has_preferred_x;
        char single_line;
        char padding1;
        char padding2;
        char padding3;
        float preferred_x;
        StbUndoState undostate;
    }

    struct ImDrawList {
        ImVector!(ImDrawCmd) CmdBuffer;
        ImVector!(ImDrawIdx) IdxBuffer;
        ImVector!(ImDrawVert) VtxBuffer;
        ImDrawListFlags Flags;
        uint _VtxCurrentIdx;
        const ImDrawListSharedData* _Data;
        const(char)* _OwnerName;
        ImDrawVert* _VtxWritePtr;
        ImDrawIdx* _IdxWritePtr;
        ImVector!(ImVec4) _ClipRectStack;
        ImVector!(ImTextureID) _TextureIdStack;
        ImVector!(ImVec2) _Path;
        ImDrawCmdHeader _CmdHeader;
        ImDrawListSplitter _Splitter;
        float _FringeScale;
    }

    struct ImGuiStoragePair {
        ImGuiID key;
        union { int val_i; float val_f; void* val_p;} ;
    }

    struct ImDrawChannel {
        ImVector!(ImDrawCmd) _CmdBuffer;
        ImVector!(ImDrawIdx) _IdxBuffer;
    }

    struct ImDrawCmd {
        ImVec4 ClipRect;
        ImTextureID TextureId;
        uint VtxOffset;
        uint IdxOffset;
        uint ElemCount;
        ImDrawCallback UserCallback;
        void* UserCallbackData;
    }

    struct ImGuiLastItemDataBackup {
        ImGuiID LastItemId;
        ImGuiItemStatusFlags LastItemStatusFlags;
        ImRect LastItemRect;
        ImRect LastItemDisplayRect;
    }

    struct ImGuiContextHook {
        ImGuiID HookId;
        ImGuiContextHookType Type;
        ImGuiID Owner;
        ImGuiContextHookCallback Callback;
        void* UserData;
    }

    struct StbUndoState {
        StbUndoRecord[99] undo_rec;
        ImWchar[999] undo_char;
        short undo_point;
        short redo_point;
        int undo_char_point;
        int redo_char_point;
    }

    struct ImFontBuilderIO {
        bool function(ImFontAtlas* atlas) FontBuilder_Build;
    }

    struct ImGuiTableColumnSettings {
        float WidthOrWeight;
        ImGuiID UserID;
        ImGuiTableColumnIdx Index;
        ImGuiTableColumnIdx DisplayOrder;
        ImGuiTableColumnIdx SortOrder;
        ImU8 SortDirection;
        ImU8 IsEnabled;
        ImU8 IsStretch;
    }

    struct ImGuiTextBuffer {
        ImVector!(char) Buf;
    }

    struct ImGuiListClipper {
        int DisplayStart;
        int DisplayEnd;
        int ItemsCount;
        int StepNo;
        int ItemsFrozen;
        float ItemsHeight;
        float StartPosY;
    }

    struct ImGuiMenuColumns {
        float Spacing;
        float Width;
        float NextWidth;
        float[3] Pos;
        float[3] NextWidths;
    }

    struct ImVec2ih {
        short x;
        short y;
    }

    struct ImGuiNextWindowData {
        ImGuiNextWindowDataFlags Flags;
        ImGuiCond PosCond;
        ImGuiCond SizeCond;
        ImGuiCond CollapsedCond;
        ImVec2 PosVal;
        ImVec2 PosPivotVal;
        ImVec2 SizeVal;
        ImVec2 ContentSizeVal;
        ImVec2 ScrollVal;
        bool CollapsedVal;
        ImRect SizeConstraintRect;
        ImGuiSizeCallback SizeCallback;
        void* SizeCallbackUserData;
        float BgAlphaVal;
        ImVec2 MenuBarOffsetMinVal;
    }

    struct ImGuiStorage {
        ImVector!(ImGuiStoragePair) Data;
    }

    struct ImGuiTabItem {
        ImGuiID ID;
        ImGuiTabItemFlags Flags;
        int LastFrameVisible;
        int LastFrameSelected;
        float Offset;
        float Width;
        float ContentWidth;
        ImS16 NameOffset;
        ImS16 BeginOrder;
        ImS16 IndexDuringLayout;
        bool WantClose;
    }


}
version (BindImGui_Static) {
    extern (C) @nogc nothrow {
        void ImDrawList_AddCircleFilled(ImDrawList* self, const ImVec2 center, float radius, ImU32 col, int num_segments);
        void igEndTable();
        ImDrawList* igGetForegroundDrawList_Nil();
        ImDrawList* igGetForegroundDrawList_WindowPtr(ImGuiWindow* window);
        ImDrawList* igGetForegroundDrawList_ViewportPtr(ImGuiViewport* viewport);
        const ImWchar* ImFontAtlas_GetGlyphRangesChineseFull(ImFontAtlas* self);
        void igBringWindowToDisplayFront(ImGuiWindow* window);
        void igInitialize(ImGuiContext* context);
        int ImFontAtlas_AddCustomRectRegular(ImFontAtlas* self, int width, int height);
        bool igIsMouseDragPastThreshold(ImGuiMouseButton button, float lock_threshold);
        void igSetWindowFontScale(float scale);
        bool igSliderFloat(const(char)* label, float* v, float v_min, float v_max, const(char)* format, ImGuiSliderFlags flags);
        void igImMax(ImVec2* pOut, const ImVec2 lhs, const ImVec2 rhs);
        void ImRect_GetTR(ImVec2* pOut, ImRect* self);
        void igTableSetupColumn(const(char)* label, ImGuiTableColumnFlags flags, float init_width_or_weight, ImGuiID user_id);
        const ImWchar* ImFontAtlas_GetGlyphRangesThai(ImFontAtlas* self);
        void ImGuiInputTextState_ClearSelection(ImGuiInputTextState* self);
        void ImFont_GrowIndex(ImFont* self, int new_size);
        void igClosePopupsOverWindow(ImGuiWindow* ref_window, bool restore_focus_to_window_under_popup);
        void ImFontAtlas_ClearInputData(ImFontAtlas* self);
        void ImGuiWindowSettings_destroy(ImGuiWindowSettings* self);
        bool igIsMouseDragging(ImGuiMouseButton button, float lock_threshold);
        void igLoadIniSettingsFromDisk(const(char)* ini_filename);
        void igImBezierCubicCalc(ImVec2* pOut, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, float t);
        const(char)* ImGuiTextBuffer_end(ImGuiTextBuffer* self);
        void ImGuiTabBar_destroy(ImGuiTabBar* self);
        void igSetClipboardText(const(char)* text);
        void igRenderColorRectWithAlphaCheckerboard(ImDrawList* draw_list, ImVec2 p_min, ImVec2 p_max, ImU32 fill_col, float grid_step, ImVec2 grid_off, float rounding, ImDrawFlags flags);
        void igFindBestWindowPosForPopup(ImVec2* pOut, ImGuiWindow* window);
        bool igRadioButton_Bool(const(char)* label, bool active);
        bool igRadioButton_IntPtr(const(char)* label, int* v, int v_button);
        void ImGuiTextFilter_Clear(ImGuiTextFilter* self);
        void ImRect_TranslateX(ImRect* self, float dx);
        void igGetWindowPos(ImVec2* pOut);
        void ImGuiIO_ClearInputCharacters(ImGuiIO* self);
        void igImBitArraySetBit(ImU32* arr, int n);
        void ImDrawDataBuilder_FlattenIntoSingleLayer(ImDrawDataBuilder* self);
        void igRenderTextWrapped(ImVec2 pos, const(char)* text, const(char)* text_end, float wrap_width);
        void igSpacing();
        void ImRect_TranslateY(ImRect* self, float dy);
        const(char)* ImGuiTextBuffer_c_str(ImGuiTextBuffer* self);
        ImGuiTabItem* igTabBarFindTabByID(ImGuiTabBar* tab_bar, ImGuiID tab_id);
        bool igDataTypeApplyOpFromText(const(char)* buf, const(char)* initial_value_buf, ImGuiDataType data_type, void* p_data, const(char)* format);
        void ImGuiInputTextState_destroy(ImGuiInputTextState* self);
        ImDrawData* igGetDrawData();
        void igRenderRectFilledRangeH(ImDrawList* draw_list, const ImRect rect, ImU32 col, float x_start_norm, float x_end_norm, float rounding);
        void igPopItemWidth();
        bool igIsWindowAppearing();
        void igGetAllocatorFunctions(ImGuiMemAllocFunc* p_alloc_func, ImGuiMemFreeFunc* p_free_func, void** p_user_data);
        const ImFontBuilderIO* igImFontAtlasGetBuilderForStbTruetype();
        ImGuiOldColumns* igFindOrCreateColumns(ImGuiWindow* window, ImGuiID id);
        void* ImGuiStorage_GetVoidPtr(ImGuiStorage* self, ImGuiID key);
        int ImGuiInputTextState_GetRedoAvailCount(ImGuiInputTextState* self);
        bool igIsPopupOpen_Str(const(char)* str_id, ImGuiPopupFlags flags);
        bool igIsPopupOpen_ID(ImGuiID id, ImGuiPopupFlags popup_flags);
        ImGuiTableSortSpecs* igTableGetSortSpecs();
        void igTableDrawBorders(ImGuiTable* table);
        ImGuiTable* ImGuiTable_ImGuiTable();
        bool igInputDouble(const(char)* label, double* v, double step, double step_fast, const(char)* format, ImGuiInputTextFlags flags);
        void igUnindent(float indent_w);
        bool igIsDragDropPayloadBeingAccepted();
        float igGetFontSize();
        float ImGuiMenuColumns_DeclColumns(ImGuiMenuColumns* self, float w0, float w1, float w2);
        void ImFontAtlas_CalcCustomRectUV(ImFontAtlas* self, const ImFontAtlasCustomRect* rect, ImVec2* out_uv_min, ImVec2* out_uv_max);
        float igGetFrameHeightWithSpacing();
        void ImDrawListSplitter_destroy(ImDrawListSplitter* self);
        void igGetItemRectMax(ImVec2* pOut);
        bool igFocusableItemRegister(ImGuiWindow* window, ImGuiID id);
        bool igDragInt(const(char)* label, int* v, float v_speed, int v_min, int v_max, const(char)* format, ImGuiSliderFlags flags);
        ImFont* igGetFont();
        bool igDragFloatRange2(const(char)* label, float* v_current_min, float* v_current_max, float v_speed, float v_min, float v_max, const(char)* format, const(char)* format_max, ImGuiSliderFlags flags);
        void igTableUpdateLayout(ImGuiTable* table);
        const(char)* igImStreolRange(const(char)* str, const(char)* str_end);
        void ImGuiStorage_Clear(ImGuiStorage* self);
        void ImGuiViewportP_UpdateWorkRect(ImGuiViewportP* self);
        bool igTableNextColumn();
        ImGuiID ImGuiWindow_GetID_Str(ImGuiWindow* self, const(char)* str, const(char)* str_end);
        ImGuiID ImGuiWindow_GetID_Ptr(ImGuiWindow* self, const void* ptr);
        ImGuiID ImGuiWindow_GetID_Int(ImGuiWindow* self, int n);
        void igImFontAtlasBuildPackCustomRects(ImFontAtlas* atlas, void* stbrp_context_opaque);
        ImGuiTableColumnFlags igTableGetColumnFlags(int column_n);
        bool igIsActiveIdUsingKey(ImGuiKey key);
        void igSetCursorScreenPos(const ImVec2 pos);
        const(char)* igImStristr(const(char)* haystack, const(char)* haystack_end, const(char)* needle, const(char)* needle_end);
        const(char)* ImFont_GetDebugName(ImFont* self);
        bool igBeginPopupContextWindow(const(char)* str_id, ImGuiPopupFlags popup_flags);
        bool igBeginTable(const(char)* str_id, int column, ImGuiTableFlags flags, const ImVec2 outer_size, float inner_width);
        bool igButtonEx(const(char)* label, const ImVec2 size_arg, ImGuiButtonFlags flags);
        void igTextEx(const(char)* text, const(char)* text_end, ImGuiTextFlags flags);
        bool ImGuiPayload_IsPreview(ImGuiPayload* self);
        void igLabelTextV(const(char)* label, const(char)* fmt, va_list args);
        const(char)* igImStrSkipBlank(const(char)* str);
        void igPushColumnsBackground();
        ImGuiWindow* ImGuiWindow_ImGuiWindow(ImGuiContext* context, const(char)* name);
        float igGetScrollMaxX();
        void ImBitVector_Create(ImBitVector* self, int sz);
        void igCloseCurrentPopup();
        void igImBitArraySetBitRange(ImU32* arr, int n, int n2);
        bool igSplitterBehavior(const ImRect bb, ImGuiID id, ImGuiAxis axis, float* size1, float* size2, float min_size1, float min_size2, float hover_extend, float hover_visibility_delay);
        ImGuiTableSortSpecs* ImGuiTableSortSpecs_ImGuiTableSortSpecs();
        void igGetMouseDragDelta(ImVec2* pOut, ImGuiMouseButton button, float lock_threshold);
        void igSetWindowCollapsed_Bool(bool collapsed, ImGuiCond cond);
        void igSetWindowCollapsed_Str(const(char)* name, bool collapsed, ImGuiCond cond);
        void igSetWindowCollapsed_WindowPtr(ImGuiWindow* window, bool collapsed, ImGuiCond cond);
        void igTableDrawContextMenu(ImGuiTable* table);
        void igTextDisabled(const(char)* fmt, ...);
        void igDebugNodeStorage(ImGuiStorage* storage, const(char)* label);
        void igFindBestWindowPosForPopupEx(ImVec2* pOut, const ImVec2 ref_pos, const ImVec2 size, ImGuiDir* last_dir, const ImRect r_outer, const ImRect r_avoid, ImGuiPopupPositionPolicy policy);
        void igTableSetColumnEnabled(int column_n, bool enabled);
        void igShowUserGuide();
        void igEndPopup();
        void igClearActiveID();
        bool igBeginChildFrame(ImGuiID id, const ImVec2 size, ImGuiWindowFlags flags);
        void ImGuiSettingsHandler_destroy(ImGuiSettingsHandler* self);
        void ImDrawList__ResetForNewFrame(ImDrawList* self);
        void ImGuiTextBuffer_append(ImGuiTextBuffer* self, const(char)* str, const(char)* str_end);
        int ImGuiInputTextState_GetUndoAvailCount(ImGuiInputTextState* self);
        void igEndFrame();
        void ImGuiTableColumn_destroy(ImGuiTableColumn* self);
        bool ImGuiTextRange_empty(ImGuiTextRange* self);
        void ImGuiInputTextState_ClearText(ImGuiInputTextState* self);
        bool igIsRectVisible_Nil(const ImVec2 size);
        bool igIsRectVisible_Vec2(const ImVec2 rect_min, const ImVec2 rect_max);
        bool ImGuiInputTextCallbackData_HasSelection(ImGuiInputTextCallbackData* self);
        float igCalcWrapWidthForPos(const ImVec2 pos, float wrap_pos_x);
        ImGuiID igGetIDWithSeed(const(char)* str_id_begin, const(char)* str_id_end, ImGuiID seed);
        int igImUpperPowerOfTwo(int v);
        bool igIsMouseClicked(ImGuiMouseButton button, bool repeat);
        void igColorConvertRGBtoHSV(float r, float g, float b, float* out_h, float* out_s, float* out_v);
        void igPushFocusScope(ImGuiID id);
        void igSetNextWindowFocus();
        ImFont* igGetDefaultFont();
        const(char)* igGetClipboardText();
        bool igIsAnyItemHovered();
        void igTableResetSettings(ImGuiTable* table);
        ImGuiListClipper* ImGuiListClipper_ImGuiListClipper();
        int igTableGetHoveredColumn();
        int igImStrlenW(const ImWchar* str);
        bool igBeginPopup(const(char)* str_id, ImGuiWindowFlags flags);
        int igTableGetRowIndex();
        ImU64 igImFileGetSize(ImFileHandle file);
        ImGuiSettingsHandler* ImGuiSettingsHandler_ImGuiSettingsHandler();
        bool igMenuItem_Bool(const(char)* label, const(char)* shortcut, bool selected, bool enabled);
        bool igMenuItem_BoolPtr(const(char)* label, const(char)* shortcut, bool* p_selected, bool enabled);
        void igImStrTrimBlanks(char* str);
        ImGuiStyleMod* ImGuiStyleMod_ImGuiStyleMod_Int(ImGuiStyleVar idx, int v);
        ImGuiStyleMod* ImGuiStyleMod_ImGuiStyleMod_Float(ImGuiStyleVar idx, float v);
        ImGuiStyleMod* ImGuiStyleMod_ImGuiStyleMod_Vec2(ImGuiStyleVar idx, ImVec2 v);
        void ImFontConfig_destroy(ImFontConfig* self);
        bool igBeginPopupEx(ImGuiID id, ImGuiWindowFlags extra_flags);
        bool igImCharIsBlankA(char c);
        void igResetMouseDragDelta(ImGuiMouseButton button);
        void ImGuiListClipper_End(ImGuiListClipper* self);
        void igSaveIniSettingsToDisk(const(char)* ini_filename);
        void igDestroyContext(ImGuiContext* ctx);
        void igSetNextWindowContentSize(const ImVec2 size);
        void igGetWindowScrollbarRect(ImRect* pOut, ImGuiWindow* window, ImGuiAxis axis);
        void igTableSetupScrollFreeze(int cols, int rows);
        ImGuiTableColumnSettings* ImGuiTableSettings_GetColumnSettings(ImGuiTableSettings* self);
        bool igInputTextMultiline(const(char)* label, char* buf, size_t buf_size, const ImVec2 size, ImGuiInputTextFlags flags, ImGuiInputTextCallback callback, void* user_data);
        bool igIsClippedEx(const ImRect bb, ImGuiID id, bool clip_even_when_logged);
        ImGuiID igGetWindowScrollbarID(ImGuiWindow* window, ImGuiAxis axis);
        bool ImGuiTextFilter_IsActive(ImGuiTextFilter* self);
        ImDrawListSharedData* ImDrawListSharedData_ImDrawListSharedData();
        bool ImFontAtlas_GetMouseCursorTexData(ImFontAtlas* self, ImGuiMouseCursor cursor, ImVec2* out_offset, ImVec2* out_size, ImVec2[2]*/*[2]*/ out_uv_border, ImVec2[2]*/*[2]*/ out_uv_fill);
        void igLogText(const(char)* fmt, ...);
        ImGuiTableColumnSettings* ImGuiTableColumnSettings_ImGuiTableColumnSettings();
        int igImStrnicmp(const(char)* str1, const(char)* str2, size_t count);
        void igColorEditOptionsPopup(const float* col, ImGuiColorEditFlags flags);
        float igGetTextLineHeightWithSpacing();
        void igTableFixColumnSortDirection(ImGuiTable* table, ImGuiTableColumn* column);
        void igPushStyleVar_Float(ImGuiStyleVar idx, float val);
        void igPushStyleVar_Vec2(ImGuiStyleVar idx, const ImVec2 val);
        bool igIsActiveIdUsingNavInput(ImGuiNavInput input);
        ImGuiInputTextState* igGetInputTextState(ImGuiID id);
        const(char)* igFindRenderedTextEnd(const(char)* text, const(char)* text_end);
        void ImFontAtlas_ClearFonts(ImFontAtlas* self);
        void igTextColoredV(const ImVec4 col, const(char)* fmt, va_list args);
        bool igIsKeyReleased(int user_key_index);
        void igTabItemLabelAndCloseButton(ImDrawList* draw_list, const ImRect bb, ImGuiTabItemFlags flags, ImVec2 frame_padding, const(char)* label, ImGuiID tab_id, ImGuiID close_button_id, bool is_contents_visible, bool* out_just_closed, bool* out_text_clipped);
        ImGuiTableColumnSortSpecs* ImGuiTableColumnSortSpecs_ImGuiTableColumnSortSpecs();
        void igLogToClipboard(int auto_open_depth);
        const ImWchar* ImFontAtlas_GetGlyphRangesKorean(ImFontAtlas* self);
        void ImFontGlyphRangesBuilder_SetBit(ImFontGlyphRangesBuilder* self, size_t n);
        void igLogSetNextTextDecoration(const(char)* prefix, const(char)* suffix);
        void igStyleColorsClassic(ImGuiStyle* dst);
        int ImGuiTabBar_GetTabOrder(ImGuiTabBar* self, const ImGuiTabItem* tab);
        bool igBegin(const(char)* name, bool* p_open, ImGuiWindowFlags flags);
        ImGuiLastItemDataBackup* ImGuiLastItemDataBackup_ImGuiLastItemDataBackup();
        bool igBeginMenuBar();
        bool igDataTypeClamp(ImGuiDataType data_type, void* p_data, const void* p_min, const void* p_max);
        bool igButton(const(char)* label, const ImVec2 size);
        void ImFontGlyphRangesBuilder_Clear(ImFontGlyphRangesBuilder* self);
        void ImGuiMenuColumns_destroy(ImGuiMenuColumns* self);
        void igImStrncpy(char* dst, const(char)* src, size_t count);
        ImGuiNextWindowData* ImGuiNextWindowData_ImGuiNextWindowData();
        void igImBezierCubicClosestPointCasteljau(ImVec2* pOut, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, const ImVec2 p, float tess_tol);
        bool igItemAdd(const ImRect bb, ImGuiID id, const ImRect* nav_bb);
        bool igIsWindowNavFocusable(ImGuiWindow* window);
        float igGetScrollY();
        ImGuiOldColumnData* ImGuiOldColumnData_ImGuiOldColumnData();
        float ImRect_GetWidth(ImRect* self);
        void igEndListBox();
        ImGuiItemStatusFlags igGetItemStatusFlags();
        void igPopFocusScope();
        const ImVec4* igGetStyleColorVec4(ImGuiCol idx);
        ImGuiTable* igTableFindByID(ImGuiID id);
        void igShutdown(ImGuiContext* context);
        void igRenderText(ImVec2 pos, const(char)* text, const(char)* text_end, bool hide_text_after_hash);
        void igTablePushBackgroundChannel();
        void ImRect_ClipWith(ImRect* self, const ImRect r);
        void ImRect_GetTL(ImVec2* pOut, ImRect* self);
        ImDrawListSplitter* ImDrawListSplitter_ImDrawListSplitter();
        int ImDrawList__CalcCircleAutoSegmentCount(ImDrawList* self, float radius);
        void igSetWindowFocus_Nil();
        void igSetWindowFocus_Str(const(char)* name);
        bool igInvisibleButton(const(char)* str_id, const ImVec2 size, ImGuiButtonFlags flags);
        bool igTableSetColumnIndex(int column_n);
        void igRenderMouseCursor(ImDrawList* draw_list, ImVec2 pos, float scale, ImGuiMouseCursor mouse_cursor, ImU32 col_fill, ImU32 col_border, ImU32 col_shadow);
        void igImFontAtlasBuildInit(ImFontAtlas* atlas);
        void igTextColored(const ImVec4 col, const(char)* fmt, ...);
        bool igSliderScalar(const(char)* label, ImGuiDataType data_type, void* p_data, const void* p_min, const void* p_max, const(char)* format, ImGuiSliderFlags flags);
        void ImDrawListSplitter_ClearFreeMemory(ImDrawListSplitter* self);
        ImGuiStyle* ImGuiStyle_ImGuiStyle();
        void ImGuiOldColumnData_destroy(ImGuiOldColumnData* self);
        ImFontConfig* ImFontConfig_ImFontConfig();
        bool igIsMouseDown(ImGuiMouseButton button);
        const(char)* ImGuiTabBar_GetTabName(ImGuiTabBar* self, const ImGuiTabItem* tab);
        void igDebugNodeTabBar(ImGuiTabBar* tab_bar, const(char)* label);
        void igNewLine();
        void igMemFree(void* ptr);
        int igCalcTypematicRepeatAmount(float t0, float t1, float repeat_delay, float repeat_rate);
        void igNextColumn();
        void igRenderFrame(ImVec2 p_min, ImVec2 p_max, ImU32 fill_col, bool border, float rounding);
        void igLogButtons();
        void igEndTabItem();
        void ImFont_ClearOutputData(ImFont* self);
        ImFont* ImFont_ImFont();
        void igRenderArrowPointingAt(ImDrawList* draw_list, ImVec2 pos, ImVec2 half_sz, ImGuiDir direction, ImU32 col);
        bool igVSliderFloat(const(char)* label, const ImVec2 size, float* v, float v_min, float v_max, const(char)* format, ImGuiSliderFlags flags);
        void igTableUpdateBorders(ImGuiTable* table);
        void igEndGroup();
        void igPlotLines_FloatPtr(const(char)* label, const float* values, int values_count, int values_offset, const(char)* overlay_text, float scale_min, float scale_max, ImVec2 graph_size, int stride);
        void igPlotLines_FnFloatPtr(const(char)* label, float function(void* data,int idx) values_getter, void* data, int values_count, int values_offset, const(char)* overlay_text, float scale_min, float scale_max, ImVec2 graph_size);
        float igGetColumnNormFromOffset(const ImGuiOldColumns* columns, float offset);
        void igSetCurrentFont(ImFont* font);
        void igSetItemAllowOverlap();
        void** ImGuiStorage_GetVoidPtrRef(ImGuiStorage* self, ImGuiID key, void* default_val);
        bool igCheckboxFlags_IntPtr(const(char)* label, int* flags, int flags_value);
        bool igCheckboxFlags_UintPtr(const(char)* label, uint* flags, uint flags_value);
        bool igCheckboxFlags_S64Ptr(const(char)* label, ImS64* flags, ImS64 flags_value);
        bool igCheckboxFlags_U64Ptr(const(char)* label, ImU64* flags, ImU64 flags_value);
        void ImGuiNavMoveResult_Clear(ImGuiNavMoveResult* self);
        void ImRect_destroy(ImRect* self);
        void igImTriangleBarycentricCoords(const ImVec2 a, const ImVec2 b, const ImVec2 c, const ImVec2 p, float* out_u, float* out_v, float* out_w);
        bool igTreeNodeBehavior(ImGuiID id, ImGuiTreeNodeFlags flags, const(char)* label, const(char)* label_end);
        void ImFontGlyphRangesBuilder_AddRanges(ImFontGlyphRangesBuilder* self, const ImWchar* ranges);
        void igTableSetBgColor(ImGuiTableBgTarget target, ImU32 color, int column_n);
        const ImWchar* ImFontAtlas_GetGlyphRangesVietnamese(ImFontAtlas* self);
        ImGuiContextHook* ImGuiContextHook_ImGuiContextHook();
        const(char)* igGetVersion();
        ImDrawList* ImDrawList_ImDrawList(const ImDrawListSharedData* shared_data);
        void igRenderTextEllipsis(ImDrawList* draw_list, const ImVec2 pos_min, const ImVec2 pos_max, float clip_max_x, float ellipsis_max_x, const(char)* text, const(char)* text_end, const ImVec2* text_size_if_known);
        void ImGuiListClipper_destroy(ImGuiListClipper* self);
        void ImGuiTableSortSpecs_destroy(ImGuiTableSortSpecs* self);
        void igPushOverrideID(ImGuiID id);
        void igImMul(ImVec2* pOut, const ImVec2 lhs, const ImVec2 rhs);
        void igSetScrollY_Float(float scroll_y);
        void igSetScrollY_WindowPtr(ImGuiWindow* window, float scroll_y);
        const(char)* ImFont_CalcWordWrapPositionA(ImFont* self, float scale, const(char)* text, const(char)* text_end, float wrap_width);
        bool igSmallButton(const(char)* label);
        ImGuiTableColumn* ImGuiTableColumn_ImGuiTableColumn();
        void ImGuiWindow_destroy(ImGuiWindow* self);
        ImGuiID igTableGetColumnResizeID(const ImGuiTable* table, int column_n, int instance_no);
        bool igCombo_Str_arr(const(char)* label, int* current_item, const(char)** items, int items_count, int popup_max_height_in_items);
        bool igCombo_Str(const(char)* label, int* current_item, const(char)* items_separated_by_zeros, int popup_max_height_in_items);
        bool igCombo_FnBoolPtr(const(char)* label, int* current_item, bool function(void* data,int idx,const(char)** out_text) items_getter, void* data, int items_count, int popup_max_height_in_items);
        bool igIsWindowChildOf(ImGuiWindow* window, ImGuiWindow* potential_parent);
        float ImGuiWindow_CalcFontSize(ImGuiWindow* self);
        void igTableSetColumnWidth(int column_n, float width);
        void ImDrawList_AddLine(ImDrawList* self, const ImVec2 p1, const ImVec2 p2, ImU32 col, float thickness);
        void ImDrawList_AddCircle(ImDrawList* self, const ImVec2 center, float radius, ImU32 col, int num_segments, float thickness);
        void ImGuiInputTextState_SelectAll(ImGuiInputTextState* self);
        const(char)* igImParseFormatTrimDecorations(const(char)* format, char* buf, size_t buf_size);
        ImGuiMetricsConfig* ImGuiMetricsConfig_ImGuiMetricsConfig();
        ImGuiTabBar* ImGuiTabBar_ImGuiTabBar();
        void ImGuiViewport_GetCenter(ImVec2* pOut, ImGuiViewport* self);
        void igDebugDrawItemRect(ImU32 col);
        bool igTreeNodeBehaviorIsOpen(ImGuiID id, ImGuiTreeNodeFlags flags);
        int igImTextCountUtf8BytesFromChar(const(char)* in_text, const(char)* in_text_end);
        void igSetMouseCursor(ImGuiMouseCursor cursor_type);
        void igBeginColumns(const(char)* str_id, int count, ImGuiOldColumnFlags flags);
        ImGuiIO* igGetIO();
        bool igDragBehavior(ImGuiID id, ImGuiDataType data_type, void* p_v, float v_speed, const void* p_min, const void* p_max, const(char)* format, ImGuiSliderFlags flags);
        int igImModPositive(int a, int b);
        void ImFontAtlasCustomRect_destroy(ImFontAtlasCustomRect* self);
        void ImGuiPayload_destroy(ImGuiPayload* self);
        void igEndMenu();
        float igImSaturate(float f);
        void ImDrawList_PrimRect(ImDrawList* self, const ImVec2 a, const ImVec2 b, ImU32 col);
        float igImLinearSweep(float current, float target, float speed);
        void igUpdateMouseMovingWindowNewFrame();
        void ImDrawList_AddRectFilled(ImDrawList* self, const ImVec2 p_min, const ImVec2 p_max, ImU32 col, float rounding, ImDrawFlags flags);
        void ImGuiPopupData_destroy(ImGuiPopupData* self);
        ImGuiSettingsHandler* igFindSettingsHandler(const(char)* type_name);
        bool igDragInt2(const(char)* label, int[2]*/*[2]*/ v, float v_speed, int v_min, int v_max, const(char)* format, ImGuiSliderFlags flags);
        void igSetColorEditOptions(ImGuiColorEditFlags flags);
        bool igIsAnyMouseDown();
        void ImGuiTextFilter_Build(ImGuiTextFilter* self);
        void igTabItemCalcSize(ImVec2* pOut, const(char)* label, bool has_close_button);
        void igSetNextWindowCollapsed(bool collapsed, ImGuiCond cond);
        void igSetLastItemData(ImGuiWindow* window, ImGuiID item_id, ImGuiItemStatusFlags status_flags, const ImRect item_rect);
        void igLogToBuffer(int auto_open_depth);
        void* igImFileLoadToMemory(const(char)* filename, const(char)* mode, size_t* out_file_size, int padding_bytes);
        const ImWchar* ImFontAtlas_GetGlyphRangesCyrillic(ImFontAtlas* self);
        void ImGuiStyle_destroy(ImGuiStyle* self);
        void ImDrawList_destroy(ImDrawList* self);
        void ImVec4_destroy(ImVec4* self);
        void igRenderCheckMark(ImDrawList* draw_list, ImVec2 pos, ImU32 col, float sz);
        bool igTreeNodeEx_Str(const(char)* label, ImGuiTreeNodeFlags flags);
        bool igTreeNodeEx_StrStr(const(char)* str_id, ImGuiTreeNodeFlags flags, const(char)* fmt, ...);
        bool igTreeNodeEx_Ptr(const void* ptr_id, ImGuiTreeNodeFlags flags, const(char)* fmt, ...);
        void ImBitVector_SetBit(ImBitVector* self, int n);
        void igSetColumnWidth(int column_index, float width);
        void ImGuiNavMoveResult_destroy(ImGuiNavMoveResult* self);
        bool igIsItemClicked(ImGuiMouseButton mouse_button);
        void igTableOpenContextMenu(int column_n);
        void ImDrawList_AddCallback(ImDrawList* self, ImDrawCallback callback, void* callback_data);
        void igGetMousePos(ImVec2* pOut);
        int igDataTypeCompare(ImGuiDataType data_type, const void* arg_1, const void* arg_2);
        bool igImageButtonEx(ImGuiID id, ImTextureID texture_id, const ImVec2 size, const ImVec2 uv0, const ImVec2 uv1, const ImVec2 padding, const ImVec4 bg_col, const ImVec4 tint_col);
        void ImDrawListSharedData_SetCircleTessellationMaxError(ImDrawListSharedData* self, float max_error);
        ImGuiID igGetWindowResizeID(ImGuiWindow* window, int n);
        void igBullet();
        void igTableSaveSettings(ImGuiTable* table);
        ImGuiTableSettings* igTableGetBoundSettings(ImGuiTable* table);
        ImGuiID igGetHoveredID();
        void igGetWindowContentRegionMin(ImVec2* pOut);
        void igTableHeadersRow();
        void ImDrawList_AddNgonFilled(ImDrawList* self, const ImVec2 center, float radius, ImU32 col, int num_segments);
        bool igDragScalar(const(char)* label, ImGuiDataType data_type, void* p_data, float v_speed, const void* p_min, const void* p_max, const(char)* format, ImGuiSliderFlags flags);
        void igSetCursorPos(const ImVec2 local_pos);
        void igGcCompactTransientMiscBuffers();
        void igEndColumns();
        void igSetTooltip(const(char)* fmt, ...);
        const(char)* igTableGetColumnName_Int(int column_n);
        const(char)* igTableGetColumnName_TablePtr(const ImGuiTable* table, int column_n);
        void ImGuiViewportP_destroy(ImGuiViewportP* self);
        bool igBeginTabBarEx(ImGuiTabBar* tab_bar, const ImRect bb, ImGuiTabBarFlags flags);
        void igShadeVertsLinearColorGradientKeepAlpha(ImDrawList* draw_list, int vert_start_idx, int vert_end_idx, ImVec2 gradient_p0, ImVec2 gradient_p1, ImU32 col0, ImU32 col1);
        bool ImGuiInputTextState_HasSelection(ImGuiInputTextState* self);
        float igCalcItemWidth();
        void igPushItemWidth(float item_width);
        bool igScrollbarEx(const ImRect bb, ImGuiID id, ImGuiAxis axis, float* p_scroll_v, float avail_v, float contents_v, ImDrawFlags flags);
        void ImDrawList_ChannelsMerge(ImDrawList* self);
        void igSetAllocatorFunctions(ImGuiMemAllocFunc alloc_func, ImGuiMemFreeFunc free_func, void* user_data);
        const ImFontGlyph* ImFont_FindGlyph(ImFont* self, ImWchar c);
        void igDebugStartItemPicker();
        void ImGuiNextWindowData_destroy(ImGuiNextWindowData* self);
        bool ImGuiPayload_IsDelivery(ImGuiPayload* self);
        const ImWchar* ImFontAtlas_GetGlyphRangesJapanese(ImFontAtlas* self);
        bool ImRect_Overlaps(ImRect* self, const ImRect r);
        void igCaptureMouseFromApp(bool want_capture_mouse_value);
        ImGuiID igAddContextHook(ImGuiContext* context, const ImGuiContextHook* hook);
        ImGuiID igImHashData(const void* data, size_t data_size, ImU32 seed);
        void ImGuiInputTextCallbackData_InsertChars(ImGuiInputTextCallbackData* self, int pos, const(char)* text, const(char)* text_end);
        bool igDragFloat2(const(char)* label, float[2]*/*[2]*/ v, float v_speed, float v_min, float v_max, const(char)* format, ImGuiSliderFlags flags);
        void igTreePushOverrideID(ImGuiID id);
        void igUpdateHoveredWindowAndCaptureFlags();
        void ImFont_destroy(ImFont* self);
        void igEndMenuBar();
        void igGetWindowSize(ImVec2* pOut);
        bool igInputInt4(const(char)* label, int[4]*/*[4]*/ v, ImGuiInputTextFlags flags);
        float igImSign_Float(float x);
        double igImSign_double(double x);
        void ImDrawList_AddBezierQuadratic(ImDrawList* self, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, ImU32 col, float thickness, int num_segments);
        ImGuiMouseCursor igGetMouseCursor();
        bool igIsMouseDoubleClicked(ImGuiMouseButton button);
        void igLabelText(const(char)* label, const(char)* fmt, ...);
        void ImDrawList_PathClear(ImDrawList* self);
        void ImDrawCmd_destroy(ImDrawCmd* self);
        ImGuiStorage* igGetStateStorage();
        bool igInputInt2(const(char)* label, int[2]*/*[2]*/ v, ImGuiInputTextFlags flags);
        ImU64 igImFileRead(void* data, ImU64 size, ImU64 count, ImFileHandle file);
        void igImFontAtlasBuildRender32bppRectFromString(ImFontAtlas* atlas, int x, int y, int w, int h, const(char)* in_str, char in_marker_char, uint in_marker_pixel_value);
        void ImGuiOldColumns_destroy(ImGuiOldColumns* self);
        void igSetNextWindowScroll(const ImVec2 scroll);
        float igGetFrameHeight();
        ImU64 igImFileWrite(const void* data, ImU64 size, ImU64 count, ImFileHandle file);
        bool igInputText(const(char)* label, char* buf, size_t buf_size, ImGuiInputTextFlags flags, ImGuiInputTextCallback callback, void* user_data);
        bool igTreeNodeExV_Str(const(char)* str_id, ImGuiTreeNodeFlags flags, const(char)* fmt, va_list args);
        bool igTreeNodeExV_Ptr(const void* ptr_id, ImGuiTreeNodeFlags flags, const(char)* fmt, va_list args);
        void igTableSetColumnSortDirection(int column_n, ImGuiSortDirection sort_direction, bool append_to_sort_specs);
        bool igIsAnyItemFocused();
        void ImDrawDataBuilder_Clear(ImDrawDataBuilder* self);
        ImVec2ih* ImVec2ih_ImVec2ih_Nil();
        ImVec2ih* ImVec2ih_ImVec2ih_short(short _x, short _y);
        ImVec2ih* ImVec2ih_ImVec2ih_Vec2(const ImVec2 rhs);
        void igPopStyleColor(int count);
        ImVec1* ImVec1_ImVec1_Nil();
        ImVec1* ImVec1_ImVec1_Float(float _x);
        void igCalcItemSize(ImVec2* pOut, ImVec2 size, float default_w, float default_h);
        bool ImFontAtlasCustomRect_IsPacked(ImFontAtlasCustomRect* self);
        bool igColorEdit4(const(char)* label, float[4]*/*[4]*/ col, ImGuiColorEditFlags flags);
        int igPlotEx(ImGuiPlotType plot_type, const(char)* label, float function(void* data,int idx) values_getter, void* data, int values_count, int values_offset, const(char)* overlay_text, float scale_min, float scale_max, ImVec2 frame_size);
        void igGetCursorStartPos(ImVec2* pOut);
        void ImGuiInputTextCallbackData_destroy(ImGuiInputTextCallbackData* self);
        bool ImFontAtlas_IsBuilt(ImFontAtlas* self);
        const(char)* ImGuiTextBuffer_begin(ImGuiTextBuffer* self);
        void ImGuiTable_destroy(ImGuiTable* self);
        ImGuiID ImGuiWindow_GetIDNoKeepAlive_Str(ImGuiWindow* self, const(char)* str, const(char)* str_end);
        ImGuiID ImGuiWindow_GetIDNoKeepAlive_Ptr(ImGuiWindow* self, const void* ptr);
        ImGuiID ImGuiWindow_GetIDNoKeepAlive_Int(ImGuiWindow* self, int n);
        void ImFont_BuildLookupTable(ImFont* self);
        void ImGuiTextBuffer_appendfv(ImGuiTextBuffer* self, const(char)* fmt, va_list args);
        ImVec4* ImVec4_ImVec4_Nil();
        ImVec4* ImVec4_ImVec4_Float(float _x, float _y, float _z, float _w);
        void igClearIniSettings();
        int igImTextCountCharsFromUtf8(const(char)* in_text, const(char)* in_text_end);
        void ImDrawList_PathLineToMergeDuplicate(ImDrawList* self, const ImVec2 pos);
        ImGuiIO* ImGuiIO_ImGuiIO();
        bool igDragInt4(const(char)* label, int[4]*/*[4]*/ v, float v_speed, int v_min, int v_max, const(char)* format, ImGuiSliderFlags flags);
        bool igBeginDragDropTarget();
        void igTablePopBackgroundChannel();
        void ImGuiTextBuffer_clear(ImGuiTextBuffer* self);
        int igImStricmp(const(char)* str1, const(char)* str2);
        void igMarkItemEdited(ImGuiID id);
        bool igIsWindowFocused(ImGuiFocusedFlags flags);
        ImGuiTableSettings* igTableSettingsCreate(ImGuiID id, int columns_count);
        void ImGuiIO_AddInputCharactersUTF8(ImGuiIO* self, const(char)* str);
        void ImGuiTableSettings_destroy(ImGuiTableSettings* self);
        bool igIsWindowAbove(ImGuiWindow* potential_above, ImGuiWindow* potential_below);
        void ImDrawList__PathArcToN(ImDrawList* self, const ImVec2 center, float radius, float a_min, float a_max, int num_segments);
        void igColorTooltip(const(char)* text, const float* col, ImGuiColorEditFlags flags);
        void igSetCurrentContext(ImGuiContext* ctx);
        void igImTriangleClosestPoint(ImVec2* pOut, const ImVec2 a, const ImVec2 b, const ImVec2 c, const ImVec2 p);
        bool igSliderInt4(const(char)* label, int[4]*/*[4]*/ v, int v_min, int v_max, const(char)* format, ImGuiSliderFlags flags);
        void igGetItemRectMin(ImVec2* pOut);
        void igTableUpdateColumnsWeightFromWidth(ImGuiTable* table);
        void ImDrawList_PrimReserve(ImDrawList* self, int idx_count, int vtx_count);
        ImGuiMenuColumns* ImGuiMenuColumns_ImGuiMenuColumns();
        void ImDrawList_AddRectFilledMultiColor(ImDrawList* self, const ImVec2 p_min, const ImVec2 p_max, ImU32 col_upr_left, ImU32 col_upr_right, ImU32 col_bot_right, ImU32 col_bot_left);
        float igImPow_Float(float x, float y);
        double igImPow_double(double x, double y);
        void igSeparatorEx(ImGuiSeparatorFlags flags);
        void igSetStateStorage(ImGuiStorage* storage);
        void ImGuiStorage_SetAllInt(ImGuiStorage* self, int val);
        bool ImGuiListClipper_Step(ImGuiListClipper* self);
        void ImGuiOnceUponAFrame_destroy(ImGuiOnceUponAFrame* self);
        void ImGuiInputTextCallbackData_DeleteChars(ImGuiInputTextCallbackData* self, int pos, int bytes_count);
        void igImFontAtlasBuildSetupFont(ImFontAtlas* atlas, ImFont* font, ImFontConfig* font_config, float ascent, float descent);
        bool ImGuiTextBuffer_empty(ImGuiTextBuffer* self);
        void igShowDemoWindow(bool* p_open);
        void ImGuiTextRange_destroy(ImGuiTextRange* self);
        void ImGuiStorage_SetVoidPtr(ImGuiStorage* self, ImGuiID key, void* val);
        float igImInvLength(const ImVec2 lhs, float fail_value);
        ImGuiID igGetFocusScope();
        bool igCloseButton(ImGuiID id, const ImVec2 pos);
        void igTableSettingsInstallHandler(ImGuiContext* context);
        void ImDrawList_PushTextureID(ImDrawList* self, ImTextureID texture_id);
        void ImDrawList_PathLineTo(ImDrawList* self, const ImVec2 pos);
        void igSetWindowHitTestHole(ImGuiWindow* window, const ImVec2 pos, const ImVec2 size);
        void ImRect_Add_Vec2(ImRect* self, const ImVec2 p);
        void ImRect_Add_Rect(ImRect* self, const ImRect r);
        void igShowMetricsWindow(bool* p_open);
        void ImDrawList__PopUnusedDrawCmd(ImDrawList* self);
        void ImDrawList_AddImageRounded(ImDrawList* self, ImTextureID user_texture_id, const ImVec2 p_min, const ImVec2 p_max, const ImVec2 uv_min, const ImVec2 uv_max, ImU32 col, float rounding, ImDrawFlags flags);
        void ImGuiStyleMod_destroy(ImGuiStyleMod* self);
        void ImGuiStorage_BuildSortByKey(ImGuiStorage* self);
        void igTableSetupDrawChannels(ImGuiTable* table);
        void ImDrawList_PathRect(ImDrawList* self, const ImVec2 rect_min, const ImVec2 rect_max, float rounding, ImDrawFlags flags);
        bool igInputTextEx(const(char)* label, const(char)* hint, char* buf, int buf_size, const ImVec2 size_arg, ImGuiInputTextFlags flags, ImGuiInputTextCallback callback, void* user_data);
        bool igColorEdit3(const(char)* label, float[3]*/*[3]*/ col, ImGuiColorEditFlags flags);
        void ImColor_destroy(ImColor* self);
        bool igIsItemToggledSelection();
        bool igTabItemEx(ImGuiTabBar* tab_bar, const(char)* label, bool* p_open, ImGuiTabItemFlags flags);
        bool igIsKeyPressedMap(ImGuiKey key, bool repeat);
        void igLogFinish();
        void igGetItemRectSize(ImVec2* pOut);
        const(char)* igImParseFormatFindStart(const(char)* format);
        bool igDragScalarN(const(char)* label, ImGuiDataType data_type, void* p_data, int components, float v_speed, const void* p_min, const void* p_max, const(char)* format, ImGuiSliderFlags flags);
        ImDrawData* ImDrawData_ImDrawData();
        float igImDot(const ImVec2 a, const ImVec2 b);
        void igMarkIniSettingsDirty_Nil();
        void igMarkIniSettingsDirty_WindowPtr(ImGuiWindow* window);
        int igTableGetColumnCount();
        float igGetWindowWidth();
        void igBulletTextV(const(char)* fmt, va_list args);
        void igPushTextWrapPos(float wrap_local_pos_x);
        void ImDrawListSplitter_SetCurrentChannel(ImDrawListSplitter* self, ImDrawList* draw_list, int channel_idx);
        void ImGuiStorage_SetBool(ImGuiStorage* self, ImGuiID key, bool val);
        void igAlignTextToFramePadding();
        bool igIsWindowHovered(ImGuiHoveredFlags flags);
        void ImRect_GetCenter(ImVec2* pOut, ImRect* self);
        float igGetWindowContentRegionWidth();
        void ImDrawList_PathArcTo(ImDrawList* self, const ImVec2 center, float radius, float a_min, float a_max, int num_segments);
        bool igIsAnyItemActive();
        void igStyleColorsDark(ImGuiStyle* dst);
        float igGetTreeNodeToLabelSpacing();
        void igSameLine(float offset_from_start_x, float spacing);
        void igTabBarQueueReorder(ImGuiTabBar* tab_bar, const ImGuiTabItem* tab, int dir);
        void igDummy(const ImVec2 size);
        ImGuiID igGetItemID();
        bool igImageButton(ImTextureID user_texture_id, const ImVec2 size, const ImVec2 uv0, const ImVec2 uv1, int frame_padding, const ImVec4 bg_col, const ImVec4 tint_col);
        void igGetWindowContentRegionMax(ImVec2* pOut);
        int igGetKeyPressedAmount(int key_index, float repeat_delay, float rate);
        void igRenderTextClipped(const ImVec2 pos_min, const ImVec2 pos_max, const(char)* text, const(char)* text_end, const ImVec2* text_size_if_known, const ImVec2 alignment, const ImRect* clip_rect);
        bool igImIsPowerOfTwo_Int(int v);
        bool igImIsPowerOfTwo_U64(ImU64 v);
        void igSetNextWindowSizeConstraints(const ImVec2 size_min, const ImVec2 size_max, ImGuiSizeCallback custom_callback, void* custom_callback_data);
        void igTableGcCompactTransientBuffers(ImGuiTable* table);
        const ImFontGlyph* ImFont_FindGlyphNoFallback(ImFont* self, ImWchar c);
        bool igShowStyleSelector(const(char)* label);
        void igFocusableItemUnregister(ImGuiWindow* window);
        void igNavMoveRequestForward(ImGuiDir move_dir, ImGuiDir clip_dir, const ImRect bb_rel, ImGuiNavMoveFlags move_flags);
        void igNavInitWindow(ImGuiWindow* window, bool force_reinit);
        ImFileHandle igImFileOpen(const(char)* filename, const(char)* mode);
        void igEndDragDropTarget();
        ImGuiWindowSettings* ImGuiWindowSettings_ImGuiWindowSettings();
        void ImDrawListSharedData_destroy(ImDrawListSharedData* self);
        bool ImFontAtlas_Build(ImFontAtlas* self);
        void igSetScrollFromPosX_Float(float local_x, float center_x_ratio);
        void igSetScrollFromPosX_WindowPtr(ImGuiWindow* window, float local_x, float center_x_ratio);
        bool igIsKeyPressed(int user_key_index, bool repeat);
        void igEndTooltip();
        ImGuiWindowSettings* igFindWindowSettings(ImGuiID id);
        void igDebugRenderViewportThumbnail(ImDrawList* draw_list, ImGuiViewportP* viewport, const ImRect bb);
        void igKeepAliveID(ImGuiID id);
        float igGetColumnOffsetFromNorm(const ImGuiOldColumns* columns, float offset_norm);
        bool ImFont_IsLoaded(ImFont* self);
        void igDebugNodeDrawCmdShowMeshAndBoundingBox(ImDrawList* out_draw_list, const ImDrawList* draw_list, const ImDrawCmd* draw_cmd, bool show_mesh, bool show_aabb);
        bool igBeginDragDropSource(ImGuiDragDropFlags flags);
        void ImBitVector_ClearBit(ImBitVector* self, int n);
        int ImDrawDataBuilder_GetDrawListCount(ImDrawDataBuilder* self);
        float igGetCursorPosX();
        void igSetScrollFromPosY_Float(float local_y, float center_y_ratio);
        void igSetScrollFromPosY_WindowPtr(ImGuiWindow* window, float local_y, float center_y_ratio);
        bool igColorButton(const(char)* desc_id, const ImVec4 col, ImGuiColorEditFlags flags, ImVec2 size);
        const ImGuiPayload* igAcceptDragDropPayload(const(char)* type, ImGuiDragDropFlags flags);
        void ImDrawList_PopClipRect(ImDrawList* self);
        void igPushFont(ImFont* font);
        float igGetScrollMaxY();
        ImGuiStoragePair* ImGuiStoragePair_ImGuiStoragePair_Int(ImGuiID _key, int _val_i);
        ImGuiStoragePair* ImGuiStoragePair_ImGuiStoragePair_Float(ImGuiID _key, float _val_f);
        ImGuiStoragePair* ImGuiStoragePair_ImGuiStoragePair_Ptr(ImGuiID _key, void* _val_p);
        void igEndMainMenuBar();
        void ImGuiViewportP_GetMainRect(ImRect* pOut, ImGuiViewportP* self);
        float ImRect_GetArea(ImRect* self);
        bool igIsItemActive();
        void igShowAboutWindow(bool* p_open);
        void igSetNextItemWidth(float item_width);
        const(char)* igImStrchrRange(const(char)* str_begin, const(char)* str_end, char c);
        void igGetContentRegionAvail(ImVec2* pOut);
        ImGuiPayload* ImGuiPayload_ImGuiPayload();
        bool igCheckbox(const(char)* label, bool* v);
        ImGuiTextRange* ImGuiTextRange_ImGuiTextRange_Nil();
        ImGuiTextRange* ImGuiTextRange_ImGuiTextRange_Str(const(char)* _b, const(char)* _e);
        void ImFontAtlas_destroy(ImFontAtlas* self);
        void ImGuiMenuColumns_Update(ImGuiMenuColumns* self, int count, float spacing, bool clear);
        void igGcCompactTransientWindowBuffers(ImGuiWindow* window);
        void igTableSortSpecsBuild(ImGuiTable* table);
        void igNavMoveRequestTryWrapping(ImGuiWindow* window, ImGuiNavMoveFlags move_flags);
        ImGuiWindow* igGetCurrentWindow();
        void igPushStyleColor_U32(ImGuiCol idx, ImU32 col);
        void igPushStyleColor_Vec4(ImGuiCol idx, const ImVec4 col);
        void ImVec2_destroy(ImVec2* self);
        void igTableBeginRow(ImGuiTable* table);
        ImGuiID igGetID_Str(const(char)* str_id);
        ImGuiID igGetID_StrStr(const(char)* str_id_begin, const(char)* str_id_end);
        ImGuiID igGetID_Ptr(const void* ptr_id);
        bool igSetDragDropPayload(const(char)* type, const void* data, size_t sz, ImGuiCond cond);
        void igImFontAtlasBuildMultiplyCalcLookupTable(char[256]*/*[256]*/ out_table, float in_multiply_factor);
        ImFontAtlas* ImFontAtlas_ImFontAtlas();
        float ImGuiMenuColumns_CalcExtraSpace(ImGuiMenuColumns* self, float avail_w);
        void igGetContentRegionMax(ImVec2* pOut);
        void igBeginGroup();
        void igActivateItem(ImGuiID id);
        void igPopStyleVar(int count);
        void ImDrawList_PushClipRectFullScreen(ImDrawList* self);
        bool ImRect_Contains_Vec2(ImRect* self, const ImVec2 p);
        bool ImRect_Contains_Rect(ImRect* self, const ImRect r);
        void igEndChildFrame();
        void igSetColumnOffset(int column_index, float offset_x);
        void igSetKeyboardFocusHere(int offset);
        void igLoadIniSettingsFromMemory(const(char)* ini_data, size_t ini_size);
        ImDrawList* igGetBackgroundDrawList_Nil();
        ImDrawList* igGetBackgroundDrawList_ViewportPtr(ImGuiViewport* viewport);
        void igSetNextWindowSize(const ImVec2 size, ImGuiCond cond);
        bool igInputFloat3(const(char)* label, float[3]*/*[3]*/ v, const(char)* format, ImGuiInputTextFlags flags);
        void igIndent(float indent_w);
        void igTableBeginApplyRequests(ImGuiTable* table);
        bool igIsKeyDown(int user_key_index);
        void igTextUnformatted(const(char)* text, const(char)* text_end);
        void igTextV(const(char)* fmt, va_list args);
        float igImLengthSqr_Vec2(const ImVec2 lhs);
        float igImLengthSqr_Vec4(const ImVec4 lhs);
        bool ImGuiTextFilter_Draw(ImGuiTextFilter* self, const(char)* label, float width);
        void igFocusWindow(ImGuiWindow* window);
        void igPushClipRect(const ImVec2 clip_rect_min, const ImVec2 clip_rect_max, bool intersect_with_current_clip_rect);
        ImGuiViewportP* ImGuiViewportP_ImGuiViewportP();
        bool igBeginMainMenuBar();
        void ImRect_GetBR(ImVec2* pOut, ImRect* self);
        bool igCollapsingHeader_TreeNodeFlags(const(char)* label, ImGuiTreeNodeFlags flags);
        bool igCollapsingHeader_BoolPtr(const(char)* label, bool* p_visible, ImGuiTreeNodeFlags flags);
        ImGuiWindow* igGetCurrentWindowRead();
        void ImDrawList__PathArcToFastEx(ImDrawList* self, const ImVec2 center, float radius, int a_min_sample, int a_max_sample, int a_step);
        bool igSliderInt3(const(char)* label, int[3]*/*[3]*/ v, int v_min, int v_max, const(char)* format, ImGuiSliderFlags flags);
        ImGuiItemFlags igGetItemsFlags();
        ImGuiTableSettings* ImGuiTableSettings_ImGuiTableSettings();
        int igImFormatString(char* buf, size_t buf_size, const(char)* fmt, ...);
        bool igTabItemButton(const(char)* label, ImGuiTabItemFlags flags);
        bool igIsMouseReleased(ImGuiMouseButton button);
        void ImGuiInputTextState_CursorClamp(ImGuiInputTextState* self);
        void igRemoveContextHook(ImGuiContext* context, ImGuiID hook_to_remove);
        ImFontAtlasCustomRect* ImFontAtlasCustomRect_ImFontAtlasCustomRect();
        void ImGuiIO_AddInputCharacter(ImGuiIO* self, uint c);
        bool igTabBarProcessReorder(ImGuiTabBar* tab_bar);
        float igGetNavInputAmount(ImGuiNavInput n, ImGuiInputReadMode mode);
        void igClearDragDrop();
        float igGetTextLineHeight();
        void ImDrawList_AddBezierCubic(ImDrawList* self, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, ImU32 col, float thickness, int num_segments);
        void igDataTypeApplyOp(ImGuiDataType data_type, int op, void* output, const void* arg_1, const void* arg_2);
        void ImDrawList_AddQuadFilled(ImDrawList* self, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, ImU32 col);
        void igSetNextWindowBgAlpha(float alpha);
        void ImGuiInputTextCallbackData_SelectAll(ImGuiInputTextCallbackData* self);
        ImGuiNextItemData* ImGuiNextItemData_ImGuiNextItemData();
        void igLogRenderedText(const ImVec2* ref_pos, const(char)* text, const(char)* text_end);
        bool igBeginMenu(const(char)* label, bool enabled);
        int* ImGuiStorage_GetIntRef(ImGuiStorage* self, ImGuiID key, int default_val);
        int igImTextCountUtf8BytesFromStr(const ImWchar* in_text, const ImWchar* in_text_end);
        void igEndCombo();
        bool igIsNavInputTest(ImGuiNavInput n, ImGuiInputReadMode rm);
        void igImage(ImTextureID user_texture_id, const ImVec2 size, const ImVec2 uv0, const ImVec2 uv1, const ImVec4 tint_col, const ImVec4 border_col);
        void ImDrawList_AddPolyline(ImDrawList* self, const ImVec2* points, int num_points, ImU32 col, ImDrawFlags flags, float thickness);
        bool igTreeNode_Str(const(char)* label);
        bool igTreeNode_StrStr(const(char)* str_id, const(char)* fmt, ...);
        bool igTreeNode_Ptr(const void* ptr_id, const(char)* fmt, ...);
        void igPopClipRect();
        void ImDrawList_PushClipRect(ImDrawList* self, ImVec2 clip_rect_min, ImVec2 clip_rect_max, bool intersect_with_current_clip_rect);
        void igImBitArrayClearBit(ImU32* arr, int n);
        bool igArrowButtonEx(const(char)* str_id, ImGuiDir dir, ImVec2 size_arg, ImGuiButtonFlags flags);
        bool igSelectable_Bool(const(char)* label, bool selected, ImGuiSelectableFlags flags, const ImVec2 size);
        bool igSelectable_BoolPtr(const(char)* label, bool* p_selected, ImGuiSelectableFlags flags, const ImVec2 size);
        void igTableSetColumnWidthAutoSingle(ImGuiTable* table, int column_n);
        void igBeginTooltipEx(ImGuiWindowFlags extra_flags, ImGuiTooltipFlags tooltip_flags);
        ImGuiID igGetFocusID();
        void ImDrawData_DeIndexAllBuffers(ImDrawData* self);
        ImDrawCmd* ImDrawCmd_ImDrawCmd();
        void ImDrawData_ScaleClipRects(ImDrawData* self, const ImVec2 fb_scale);
        void igSetNextItemOpen(bool is_open, ImGuiCond cond);
        int igDataTypeFormatString(char* buf, int buf_size, ImGuiDataType data_type, const void* p_data, const(char)* format);
        void igTabItemBackground(ImDrawList* draw_list, const ImRect bb, ImGuiTabItemFlags flags, ImU32 col);
        void ImDrawList_AddTriangle(ImDrawList* self, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, ImU32 col, float thickness);
        void igLogToFile(int auto_open_depth, const(char)* filename);
        void ImGuiContextHook_destroy(ImGuiContextHook* self);
        bool igTempInputIsActive(ImGuiID id);
        void ImGuiNextItemData_destroy(ImGuiNextItemData* self);
        ImGuiKeyModFlags igGetMergedKeyModFlags();
        void igDebugNodeWindowSettings(ImGuiWindowSettings* settings);
        void ImRect_ToVec4(ImVec4* pOut, ImRect* self);
        void igTableGcCompactSettings();
        void igPushMultiItemsWidths(int components, float width_full);
        ImGuiContext* igCreateContext(ImFontAtlas* shared_font_atlas);
        void igTableNextRow(ImGuiTableRowFlags row_flags, float min_row_height);
        void ImGuiStackSizes_CompareWithCurrentState(ImGuiStackSizes* self);
        ImColor* ImColor_ImColor_Nil();
        ImColor* ImColor_ImColor_Int(int r, int g, int b, int a);
        ImColor* ImColor_ImColor_U32(ImU32 rgba);
        ImColor* ImColor_ImColor_Float(float r, float g, float b, float a);
        ImColor* ImColor_ImColor_Vec4(const ImVec4 col);
        float igTableGetMaxColumnWidth(const ImGuiTable* table, int column_n);
        void ImDrawList__ClearFreeMemory(ImDrawList* self);
        void igSetNavID(ImGuiID id, int nav_layer, ImGuiID focus_scope_id, const ImRect rect_rel);
        ImDrawList* igGetWindowDrawList();
        void ImRect_GetBL(ImVec2* pOut, ImRect* self);
        float igTableGetHeaderRowHeight();
        bool igIsMousePosValid(const ImVec2* mouse_pos);
        float ImGuiStorage_GetFloat(ImGuiStorage* self, ImGuiID key, float default_val);
        void igTableEndCell(ImGuiTable* table);
        bool igSliderFloat4(const(char)* label, float[4]*/*[4]*/ v, float v_min, float v_max, const(char)* format, ImGuiSliderFlags flags);
        bool igIsItemDeactivatedAfterEdit();
        void igPlotHistogram_FloatPtr(const(char)* label, const float* values, int values_count, int values_offset, const(char)* overlay_text, float scale_min, float scale_max, ImVec2 graph_size, int stride);
        void igPlotHistogram_FnFloatPtr(const(char)* label, float function(void* data,int idx) values_getter, void* data, int values_count, int values_offset, const(char)* overlay_text, float scale_min, float scale_max, ImVec2 graph_size);
        bool igIsItemEdited();
        void igShowStyleEditor(ImGuiStyle* reference);
        void igTextWrappedV(const(char)* fmt, va_list args);
        void igTableBeginCell(ImGuiTable* table, int column_n);
        ImGuiSortDirection igTableGetColumnNextSortDirection(ImGuiTableColumn* column);
        void ImGuiLastItemDataBackup_destroy(ImGuiLastItemDataBackup* self);
        void ImGuiTextBuffer_appendf(ImGuiTextBuffer* self, const(char)* fmt, ...);
        int ImFontAtlas_AddCustomRectFontGlyph(ImFontAtlas* self, ImFont* font, ImWchar id, int width, int height, float advance_x, const ImVec2 offset);
        bool igDebugCheckVersionAndDataLayout(const(char)* version_str, size_t sz_io, size_t sz_style, size_t sz_vec2, size_t sz_vec4, size_t sz_drawvert, size_t sz_drawidx);
        ImU32 igImAlphaBlendColors(ImU32 col_a, ImU32 col_b);
        bool* ImGuiStorage_GetBoolRef(ImGuiStorage* self, ImGuiID key, bool default_val);
        bool igBeginPopupContextVoid(const(char)* str_id, ImGuiPopupFlags popup_flags);
        void igSetScrollX_Float(float scroll_x);
        void igSetScrollX_WindowPtr(ImGuiWindow* window, float scroll_x);
        void igRenderNavHighlight(const ImRect bb, ImGuiID id, ImGuiNavHighlightFlags flags);
        void igBringWindowToFocusFront(ImGuiWindow* window);
        bool igSliderInt(const(char)* label, int* v, int v_min, int v_max, const(char)* format, ImGuiSliderFlags flags);
        void igUpdateMouseMovingWindowEndFrame();
        bool igInputTextWithHint(const(char)* label, const(char)* hint, char* buf, size_t buf_size, ImGuiInputTextFlags flags, ImGuiInputTextCallback callback, void* user_data);
        void igGetContentRegionMaxAbs(ImVec2* pOut);
        bool igIsMouseHoveringRect(const ImVec2 r_min, const ImVec2 r_max, bool clip);
        void ImGuiLastItemDataBackup_Backup(ImGuiLastItemDataBackup* self);
        int igImTextStrFromUtf8(ImWchar* buf, int buf_size, const(char)* in_text, const(char)* in_text_end, const char** in_remaining);
        bool igIsActiveIdUsingNavDir(ImGuiDir dir);
        void ImGuiListClipper_Begin(ImGuiListClipper* self, int items_count, float items_height);
        void igStartMouseMovingWindow(ImGuiWindow* window);
        bool igSliderInt2(const(char)* label, int[2]*/*[2]*/ v, int v_min, int v_max, const(char)* format, ImGuiSliderFlags flags);
        bool igIsItemHovered(ImGuiHoveredFlags flags);
        void igTableEndRow(ImGuiTable* table);
        void ImGuiIO_destroy(ImGuiIO* self);
        void igEndDragDropSource();
        void ImGuiStackSizes_SetToCurrentState(ImGuiStackSizes* self);
        const ImGuiPayload* igGetDragDropPayload();
        void igPopButtonRepeat();
        void ImGuiStorage_SetInt(ImGuiStorage* self, ImGuiID key, int val);
        void ImGuiWindow_MenuBarRect(ImRect* pOut, ImGuiWindow* self);
        int ImGuiStorage_GetInt(ImGuiStorage* self, ImGuiID key, int default_val);
        void igShowFontSelector(const(char)* label);
        void igImMin(ImVec2* pOut, const ImVec2 lhs, const ImVec2 rhs);
        void igPushButtonRepeat(bool repeat);
        void igTableSetColumnWidthAutoAll(ImGuiTable* table);
        float igImAbs_Float(float x);
        double igImAbs_double(double x);
        void ImGuiWindow_Rect(ImRect* pOut, ImGuiWindow* self);
        void ImGuiViewportP_GetWorkRect(ImRect* pOut, ImGuiViewportP* self);
        void ImRect_Floor(ImRect* self);
        void igTreePush_Str(const(char)* str_id);
        void igTreePush_Ptr(const void* ptr_id);
        ImU32 igColorConvertFloat4ToU32(const ImVec4 inItem);
        ImGuiStyle* igGetStyle();
        void igGetCursorPos(ImVec2* pOut);
        int igGetFrameCount();
        void ImDrawList_AddNgon(ImDrawList* self, const ImVec2 center, float radius, ImU32 col, int num_segments, float thickness);
        void igDebugNodeDrawList(ImGuiWindow* window, const ImDrawList* draw_list, const(char)* label);
        void igEnd();
        void igTabBarCloseTab(ImGuiTabBar* tab_bar, ImGuiTabItem* tab);
        bool igIsItemActivated();
        ImGuiInputTextState* ImGuiInputTextState_ImGuiInputTextState();
        float ImRect_GetHeight(ImRect* self);
        ImFont* ImFontAtlas_AddFontDefault(ImFontAtlas* self, const ImFontConfig* font_cfg);
        void ImDrawList__OnChangedTextureID(ImDrawList* self);
        int igGetColumnsCount();
        void igEndChild();
        bool igNavMoveRequestButNoResultYet();
        void ImGuiStyle_ScaleAllSizes(ImGuiStyle* self, float scale_factor);
        bool igArrowButton(const(char)* str_id, ImGuiDir dir);
        void igSetCursorPosY(float local_y);
        ImGuiTextFilter* ImGuiTextFilter_ImGuiTextFilter(const(char)* default_filter);
        void ImGuiStorage_SetFloat(ImGuiStorage* self, ImGuiID key, float val);
        void igShadeVertsLinearUV(ImDrawList* draw_list, int vert_start_idx, int vert_end_idx, const ImVec2 a, const ImVec2 b, const ImVec2 uv_a, const ImVec2 uv_b, bool clamp);
        int igTableGetColumnIndex();
        double igGetTime();
        bool igBeginPopupContextItem(const(char)* str_id, ImGuiPopupFlags popup_flags);
        void igTableLoadSettings(ImGuiTable* table);
        void igSetScrollHereX(float center_x_ratio);
        bool igSliderScalarN(const(char)* label, ImGuiDataType data_type, void* p_data, int components, const void* p_min, const void* p_max, const(char)* format, ImGuiSliderFlags flags);
        void ImDrawList_PathBezierQuadraticCurveTo(ImDrawList* self, const ImVec2 p2, const ImVec2 p3, int num_segments);
        const ImWchar* ImFontAtlas_GetGlyphRangesChineseSimplifiedCommon(ImFontAtlas* self);
        void igGetMousePosOnOpeningCurrentPopup(ImVec2* pOut);
        bool igVSliderScalar(const(char)* label, const ImVec2 size, ImGuiDataType data_type, void* p_data, const void* p_min, const void* p_max, const(char)* format, ImGuiSliderFlags flags);
        void ImFont_RenderChar(ImFont* self, ImDrawList* draw_list, float size, ImVec2 pos, ImU32 col, ImWchar c);
        void ImFont_RenderText(ImFont* self, ImDrawList* draw_list, float size, ImVec2 pos, ImU32 col, const ImVec4 clip_rect, const(char)* text_begin, const(char)* text_end, float wrap_width, bool cpu_fine_clip);
        void igOpenPopupEx(ImGuiID id, ImGuiPopupFlags popup_flags);
        void ImFontAtlas_SetTexID(ImFontAtlas* self, ImTextureID id);
        void igImFontAtlasBuildRender8bppRectFromString(ImFontAtlas* atlas, int x, int y, int w, int h, const(char)* in_str, char in_marker_char, char in_marker_pixel_value);
        void ImFontAtlas_Clear(ImFontAtlas* self);
        bool ImBitVector_TestBit(ImBitVector* self, int n);
        void ImGuiTextFilter_destroy(ImGuiTextFilter* self);
        bool igBeginPopupModal(const(char)* name, bool* p_open, ImGuiWindowFlags flags);
        ImGuiID igGetFocusedFocusScope();
        void igDebugNodeColumns(ImGuiOldColumns* columns);
        void igDebugNodeWindow(ImGuiWindow* window, const(char)* label);
        bool igInputFloat(const(char)* label, float* v, float step, float step_fast, const(char)* format, ImGuiInputTextFlags flags);
        bool igDragIntRange2(const(char)* label, int* v_current_min, int* v_current_max, float v_speed, int v_min, int v_max, const(char)* format, const(char)* format_max, ImGuiSliderFlags flags);
        void ImVec2ih_destroy(ImVec2ih* self);
        void ImDrawList_GetClipRectMax(ImVec2* pOut, ImDrawList* self);
        bool igInputFloat2(const(char)* label, float[2]*/*[2]*/ v, const(char)* format, ImGuiInputTextFlags flags);
        void ImDrawDataBuilder_ClearFreeMemory(ImDrawDataBuilder* self);
        char* ImGuiWindowSettings_GetName(ImGuiWindowSettings* self);
        void ImGuiLastItemDataBackup_Restore(ImGuiLastItemDataBackup* self);
        char* igImStrdup(const(char)* str);
        int igImFormatStringV(char* buf, size_t buf_size, const(char)* fmt, va_list args);
        void igSetTooltipV(const(char)* fmt, va_list args);
        const ImGuiDataTypeInfo* igDataTypeGetInfo(ImGuiDataType data_type);
        bool igVSliderInt(const(char)* label, const ImVec2 size, int* v, int v_min, int v_max, const(char)* format, ImGuiSliderFlags flags);
        void igSetWindowClipRectBeforeSetChannel(ImGuiWindow* window, const ImRect clip_rect);
        ImFontGlyphRangesBuilder* ImFontGlyphRangesBuilder_ImFontGlyphRangesBuilder();
        void igPopTextWrapPos();
        float ImGuiWindow_TitleBarHeight(ImGuiWindow* self);
        void ImDrawList_GetClipRectMin(ImVec2* pOut, ImDrawList* self);
        void ImDrawList_PathStroke(ImDrawList* self, ImU32 col, ImDrawFlags flags, float thickness);
        void igBeginTooltip();
        void igOpenPopupOnItemClick(const(char)* str_id, ImGuiPopupFlags popup_flags);
        void ImDrawListSplitter_Merge(ImDrawListSplitter* self, ImDrawList* draw_list);
        float ImGuiWindow_MenuBarHeight(ImGuiWindow* self);
        void ImColor_HSV(ImColor* pOut, float h, float s, float v, float a);
        bool igBeginTableEx(const(char)* name, ImGuiID id, int columns_count, ImGuiTableFlags flags, const ImVec2 outer_size, float inner_width);
        void igSetTabItemClosed(const(char)* tab_or_docked_window_label);
        void ImFont_AddGlyph(ImFont* self, const ImFontConfig* src_cfg, ImWchar c, float x0, float y0, float x1, float y1, float u0, float v0, float u1, float v1, float advance_x);
        void igSetHoveredID(ImGuiID id);
        void ImFontGlyphRangesBuilder_AddText(ImFontGlyphRangesBuilder* self, const(char)* text, const(char)* text_end);
        void ImGuiPtrOrIndex_destroy(ImGuiPtrOrIndex* self);
        ImGuiInputTextCallbackData* ImGuiInputTextCallbackData_ImGuiInputTextCallbackData();
        char* igImStrdupcpy(char* dst, size_t* p_dst_size, const(char)* str);
        bool igColorPicker4(const(char)* label, float[4]*/*[4]*/ col, ImGuiColorEditFlags flags, const float* ref_col);
        void igColorConvertHSVtoRGB(float h, float s, float v, float* out_r, float* out_g, float* out_b);
        bool igImBitArrayTestBit(const ImU32* arr, int n);
        ImGuiWindow* igFindWindowByID(ImGuiID id);
        void ImDrawList_PathBezierCubicCurveTo(ImDrawList* self, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, int num_segments);
        bool igBeginDragDropTargetCustom(const ImRect bb, ImGuiID id);
        void ImGuiContext_destroy(ImGuiContext* self);
        bool igDragInt3(const(char)* label, int[3]*/*[3]*/ v, float v_speed, int v_min, int v_max, const(char)* format, ImGuiSliderFlags flags);
        ImGuiID igImHashStr(const(char)* data, size_t data_size, ImU32 seed);
        void ImDrawList_AddTriangleFilled(ImDrawList* self, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, ImU32 col);
        bool igTempInputScalar(const ImRect bb, ImGuiID id, const(char)* label, ImGuiDataType data_type, void* p_data, const(char)* format, const void* p_clamp_min, const void* p_clamp_max);
        void igRenderArrow(ImDrawList* draw_list, ImVec2 pos, ImU32 col, ImGuiDir dir, float scale);
        void igNewFrame();
        void ImDrawList_ChannelsSetCurrent(ImDrawList* self, int n);
        ImGuiTabItem* ImGuiTabItem_ImGuiTabItem();
        ImGuiContext* ImGuiContext_ImGuiContext(ImFontAtlas* shared_font_atlas);
        void igClosePopupToLevel(int remaining, bool restore_focus_to_window_under_popup);
        bool igSliderFloat2(const(char)* label, float[2]*/*[2]*/ v, float v_min, float v_max, const(char)* format, ImGuiSliderFlags flags);
        ImGuiPopupData* ImGuiPopupData_ImGuiPopupData();
        void ImDrawList_AddImageQuad(ImDrawList* self, ImTextureID user_texture_id, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, const ImVec2 uv1, const ImVec2 uv2, const ImVec2 uv3, const ImVec2 uv4, ImU32 col);
        bool igBeginListBox(const(char)* label, const ImVec2 size);
        ImFontAtlasCustomRect* ImFontAtlas_GetCustomRectByIndex(ImFontAtlas* self, int index);
        void ImFontAtlas_GetTexDataAsAlpha8(ImFontAtlas* self, char** out_pixels, int* out_width, int* out_height, int* out_bytes_per_pixel);
        void igGcAwakeTransientWindowBuffers(ImGuiWindow* window);
        void ImDrawList__OnChangedClipRect(ImDrawList* self);
        ImGuiID igGetColumnsID(const(char)* str_id, int count);
        void igGetCursorScreenPos(ImVec2* pOut);
        void igPushAllowKeyboardFocus(bool allow_keyboard_focus);
        void ImDrawList_PopTextureID(ImDrawList* self);
        void igColumns(int count, const(char)* id, bool border);
        void ImFontGlyphRangesBuilder_AddChar(ImFontGlyphRangesBuilder* self, ImWchar c);
        int igGetColumnIndex();
        void igBringWindowToDisplayBack(ImGuiWindow* window);
        void ImDrawList_PrimVtx(ImDrawList* self, const ImVec2 pos, const ImVec2 uv, ImU32 col);
        void ImDrawListSplitter_Clear(ImDrawListSplitter* self);
        void igTableBeginInitMemory(ImGuiTable* table, int columns_count);
        void ImDrawList_AddConvexPolyFilled(ImDrawList* self, const ImVec2* points, int num_points, ImU32 col);
        bool igListBox_Str_arr(const(char)* label, int* current_item, const(char)** items, int items_count, int height_in_items);
        bool igListBox_FnBoolPtr(const(char)* label, int* current_item, bool function(void* data,int idx,const(char)** out_text) items_getter, void* data, int items_count, int height_in_items);
        void igPopItemFlag();
        void igImBezierCubicClosestPoint(ImVec2* pOut, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, const ImVec2 p, int num_segments);
        void igPopColumnsBackground();
        void igLogBegin(ImGuiLogType type, int auto_open_depth);
        bool igTreeNodeV_Str(const(char)* str_id, const(char)* fmt, va_list args);
        bool igTreeNodeV_Ptr(const void* ptr_id, const(char)* fmt, va_list args);
        void igRenderTextClippedEx(ImDrawList* draw_list, const ImVec2 pos_min, const ImVec2 pos_max, const(char)* text, const(char)* text_end, const ImVec2* text_size_if_known, const ImVec2 alignment, const ImRect* clip_rect);
        ImGuiTableSettings* igTableSettingsFindByID(ImGuiID id);
        void ImGuiIO_AddInputCharacterUTF16(ImGuiIO* self, ImWchar16 c);
        float* ImGuiStorage_GetFloatRef(ImGuiStorage* self, ImGuiID key, float default_val);
        const ImWchar* igImStrbolW(const ImWchar* buf_mid_line, const ImWchar* buf_begin);
        ImGuiStackSizes* ImGuiStackSizes_ImGuiStackSizes();
        bool igSliderBehavior(const ImRect bb, ImGuiID id, ImGuiDataType data_type, void* p_v, const void* p_min, const void* p_max, const(char)* format, ImGuiSliderFlags flags, ImRect* out_grab_bb);
        void igValue_Bool(const(char)* prefix, bool b);
        void igValue_Int(const(char)* prefix, int v);
        void igValue_Uint(const(char)* prefix, uint v);
        void igValue_Float(const(char)* prefix, float v, const(char)* float_format);
        bool igBeginTabItem(const(char)* label, bool* p_open, ImGuiTabItemFlags flags);
        void igDebugNodeTable(ImGuiTable* table);
        void ImGuiViewport_destroy(ImGuiViewport* self);
        bool igIsNavInputDown(ImGuiNavInput n);
        void ImGuiInputTextState_ClearFreeMemory(ImGuiInputTextState* self);
        void ImGuiViewport_GetWorkCenter(ImVec2* pOut, ImGuiViewport* self);
        void igRenderBullet(ImDrawList* draw_list, ImVec2 pos, ImU32 col);
        bool igDragFloat4(const(char)* label, float[4]*/*[4]*/ v, float v_speed, float v_min, float v_max, const(char)* format, ImGuiSliderFlags flags);
        void ImDrawList__OnChangedVtxOffset(ImDrawList* self);
        void igTableSortSpecsSanitize(ImGuiTable* table);
        void igFocusTopMostWindowUnderOne(ImGuiWindow* under_this_window, ImGuiWindow* ignore_window);
        void igPushID_Str(const(char)* str_id);
        void igPushID_StrStr(const(char)* str_id_begin, const(char)* str_id_end);
        void igPushID_Ptr(const void* ptr_id);
        void igPushID_Int(int int_id);
        bool igItemHoverable(const ImRect bb, ImGuiID id);
        ImFont* ImFontAtlas_AddFontFromMemoryTTF(ImFontAtlas* self, void* font_data, int font_size, float size_pixels, const ImFontConfig* font_cfg, const ImWchar* glyph_ranges);
        void igImFontAtlasBuildMultiplyRectAlpha8(const char[256]*/*[256]*/ table, char* pixels, int x, int y, int w, int h, int stride);
        void igTextDisabledV(const(char)* fmt, va_list args);
        bool igInputScalar(const(char)* label, ImGuiDataType data_type, void* p_data, const void* p_step, const void* p_step_fast, const(char)* format, ImGuiInputTextFlags flags);
        ImGuiPtrOrIndex* ImGuiPtrOrIndex_ImGuiPtrOrIndex_Ptr(void* ptr);
        ImGuiPtrOrIndex* ImGuiPtrOrIndex_ImGuiPtrOrIndex_Int(int index);
        void igImLerp_Vec2Float(ImVec2* pOut, const ImVec2 a, const ImVec2 b, float t);
        void igImLerp_Vec2Vec2(ImVec2* pOut, const ImVec2 a, const ImVec2 b, const ImVec2 t);
        void igImLerp_Vec4(ImVec4* pOut, const ImVec4 a, const ImVec4 b, float t);
        void igItemSize_Vec2(const ImVec2 size, float text_baseline_y);
        void igItemSize_Rect(const ImRect bb, float text_baseline_y);
        void ImColor_SetHSV(ImColor* self, float h, float s, float v, float a);
        bool ImFont_IsGlyphRangeUnused(ImFont* self, uint c_begin, uint c_last);
        void igImBezierQuadraticCalc(ImVec2* pOut, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, float t);
        int igImParseFormatPrecision(const(char)* format, int default_value);
        void igLogToTTY(int auto_open_depth);
        float igTableGetColumnWidthAuto(ImGuiTable* table, ImGuiTableColumn* column);
        bool igButtonBehavior(const ImRect bb, ImGuiID id, bool* out_hovered, bool* out_held, ImGuiButtonFlags flags);
        void ImGuiInputTextState_OnKeyPressed(ImGuiInputTextState* self, int key);
        float igImLog_Float(float x);
        double igImLog_double(double x);
        void igSetFocusID(ImGuiID id, ImGuiWindow* window);
        ImGuiID igGetActiveID();
        void igImLineClosestPoint(ImVec2* pOut, const ImVec2 a, const ImVec2 b, const ImVec2 p);
        bool igIsItemVisible();
        void igRender();
        float igImTriangleArea(const ImVec2 a, const ImVec2 b, const ImVec2 c);
        bool igBeginChild_Str(const(char)* str_id, const ImVec2 size, bool border, ImGuiWindowFlags flags);
        bool igBeginChild_ID(ImGuiID id, const ImVec2 size, bool border, ImGuiWindowFlags flags);
        void igStyleColorsLight(ImGuiStyle* dst);
        float igGetScrollX();
        void igGetWindowAllowedExtentRect(ImRect* pOut, ImGuiWindow* window);
        void igCallContextHooks(ImGuiContext* context, ImGuiContextHookType type);
        void ImFontAtlas_GetTexDataAsRGBA32(ImFontAtlas* self, char** out_pixels, int* out_width, int* out_height, int* out_bytes_per_pixel);
        ImGuiOnceUponAFrame* ImGuiOnceUponAFrame_ImGuiOnceUponAFrame();
        void ImDrawData_destroy(ImDrawData* self);
        void ImFont_SetFallbackChar(ImFont* self, ImWchar c);
        const(char)* igSaveIniSettingsToMemory(size_t* out_ini_size);
        ImGuiNavMoveResult* ImGuiNavMoveResult_ImGuiNavMoveResult();
        void igTabBarRemoveTab(ImGuiTabBar* tab_bar, ImGuiID tab_id);
        float igGetWindowHeight();
        ImGuiViewport* igGetMainViewport();
        bool ImGuiTextFilter_PassFilter(ImGuiTextFilter* self, const(char)* text, const(char)* text_end);
        ImFont* ImFontAtlas_AddFontFromMemoryCompressedBase85TTF(ImFontAtlas* self, const(char)* compressed_font_data_base85, float size_pixels, const ImFontConfig* font_cfg, const ImWchar* glyph_ranges);
        ImFont* ImFontAtlas_AddFontFromFileTTF(ImFontAtlas* self, const(char)* filename, float size_pixels, const ImFontConfig* font_cfg, const ImWchar* glyph_ranges);
        ImGuiContext* igGetCurrentContext();
        void igColorConvertU32ToFloat4(ImVec4* pOut, ImU32 inItem);
        void ImDrawList_PathArcToFast(ImDrawList* self, const ImVec2 center, float radius, int a_min_of_12, int a_max_of_12);
        bool igDragFloat(const(char)* label, float* v, float v_speed, float v_min, float v_max, const(char)* format, ImGuiSliderFlags flags);
        const(char)* igGetStyleColorName(ImGuiCol idx);
        void igSetItemDefaultFocus();
        void igCalcListClipping(int items_count, float items_height, int* out_items_display_start, int* out_items_display_end);
        void igSetNextWindowPos(const ImVec2 pos, ImGuiCond cond, const ImVec2 pivot);
        bool igDragFloat3(const(char)* label, float[3]*/*[3]*/ v, float v_speed, float v_min, float v_max, const(char)* format, ImGuiSliderFlags flags);
        void igCaptureKeyboardFromApp(bool want_capture_keyboard_value);
        ImGuiTable* igGetCurrentTable();
        void ImDrawData_Clear(ImDrawData* self);
        ImFont* ImFontAtlas_AddFontFromMemoryCompressedTTF(ImFontAtlas* self, const void* compressed_font_data, int compressed_font_size, float size_pixels, const ImFontConfig* font_cfg, const ImWchar* glyph_ranges);
        void ImGuiStoragePair_destroy(ImGuiStoragePair* self);
        bool igIsItemToggledOpen();
        bool igInputInt3(const(char)* label, int[3]*/*[3]*/ v, ImGuiInputTextFlags flags);
        void igShrinkWidths(ImGuiShrinkWidthItem* items, int count, float width_excess);
        void ImDrawList_AddText_Vec2(ImDrawList* self, const ImVec2 pos, ImU32 col, const(char)* text_begin, const(char)* text_end);
        void ImDrawList_AddText_FontPtr(ImDrawList* self, const ImFont* font, float font_size, const ImVec2 pos, ImU32 col, const(char)* text_begin, const(char)* text_end, float wrap_width, const ImVec4* cpu_fine_clip_rect);
        void ImDrawList_PrimRectUV(ImDrawList* self, const ImVec2 a, const ImVec2 b, const ImVec2 uv_a, const ImVec2 uv_b, ImU32 col);
        void ImDrawList_PrimWriteIdx(ImDrawList* self, ImDrawIdx idx);
        ImGuiOldColumns* ImGuiOldColumns_ImGuiOldColumns();
        void igTableRemove(ImGuiTable* table);
        void igDebugNodeTableSettings(ImGuiTableSettings* settings);
        bool ImGuiStorage_GetBool(ImGuiStorage* self, ImGuiID key, bool default_val);
        void igRenderFrameBorder(ImVec2 p_min, ImVec2 p_max, float rounding);
        ImGuiWindow* igFindWindowByName(const(char)* name);
        int igImTextStrToUtf8(char* buf, int buf_size, const ImWchar* in_text, const ImWchar* in_text_end);
        void igTextWrapped(const(char)* fmt, ...);
        void igScrollToBringRectIntoView(ImVec2* pOut, ImGuiWindow* window, const ImRect item_rect);
        bool igInputInt(const(char)* label, int* v, int step, int step_fast, ImGuiInputTextFlags flags);
        ImVec2* ImVec2_ImVec2_Nil();
        ImVec2* ImVec2_ImVec2_Float(float _x, float _y);
        int ImGuiTextBuffer_size(ImGuiTextBuffer* self);
        const ImWchar* ImFontAtlas_GetGlyphRangesDefault(ImFontAtlas* self);
        void ImFontAtlas_ClearTexData(ImFontAtlas* self);
        float ImFont_GetCharAdvance(ImFont* self, ImWchar c);
        bool igSliderFloat3(const(char)* label, float[3]*/*[3]*/ v, float v_min, float v_max, const(char)* format, ImGuiSliderFlags flags);
        void ImDrawList_PathFillConvex(ImDrawList* self, ImU32 col);
        ImGuiTextBuffer* ImGuiTextBuffer_ImGuiTextBuffer();
        void ImGuiTabItem_destroy(ImGuiTabItem* self);
        bool igSliderAngle(const(char)* label, float* v_rad, float v_degrees_min, float v_degrees_max, const(char)* format, ImGuiSliderFlags flags);
        void ImGuiTableColumnSortSpecs_destroy(ImGuiTableColumnSortSpecs* self);
        void igSetWindowPos_Vec2(const ImVec2 pos, ImGuiCond cond);
        void igSetWindowPos_Str(const(char)* name, const ImVec2 pos, ImGuiCond cond);
        void igSetWindowPos_WindowPtr(ImGuiWindow* window, const ImVec2 pos, ImGuiCond cond);
        bool igTempInputText(const ImRect bb, ImGuiID id, const(char)* label, char* buf, int buf_size, ImGuiInputTextFlags flags);
        void igSetScrollHereY(float center_y_ratio);
        ImGuiViewport* ImGuiViewport_ImGuiViewport();
        void igProgressBar(float fraction, const ImVec2 size_arg, const(char)* overlay);
        ImDrawList* ImDrawList_CloneOutput(ImDrawList* self);
        void ImFontGlyphRangesBuilder_destroy(ImFontGlyphRangesBuilder* self);
        void ImVec1_destroy(ImVec1* self);
        void igPushColumnClipRect(int column_index);
        void igLogTextV(const(char)* fmt, va_list args);
        int igImTextCharFromUtf8(uint* out_char, const(char)* in_text, const(char)* in_text_end);
        ImRect* ImRect_ImRect_Nil();
        ImRect* ImRect_ImRect_Vec2(const ImVec2 min, const ImVec2 max);
        ImRect* ImRect_ImRect_Vec4(const ImVec4 v);
        ImRect* ImRect_ImRect_Float(float x1, float y1, float x2, float y2);
        ImGuiWindow* igGetTopMostPopupModal();
        void ImDrawListSplitter_Split(ImDrawListSplitter* self, ImDrawList* draw_list, int count);
        void igBulletText(const(char)* fmt, ...);
        void igImFontAtlasBuildFinish(ImFontAtlas* atlas);
        void igDebugNodeViewport(ImGuiViewportP* viewport);
        void ImDrawList_AddQuad(ImDrawList* self, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, ImU32 col, float thickness);
        bool igIsItemDeactivated();
        ImU32 igGetColorU32_Col(ImGuiCol idx, float alpha_mul);
        ImU32 igGetColorU32_Vec4(const ImVec4 col);
        ImU32 igGetColorU32_U32(ImU32 col);
        ImGuiID ImGuiWindow_GetIDFromRectangle(ImGuiWindow* self, const ImRect r_abs);
        void ImDrawList_AddDrawCmd(ImDrawList* self);
        void igUpdateWindowParentAndRootLinks(ImGuiWindow* window, ImGuiWindowFlags flags, ImGuiWindow* parent_window);
        void igSetCursorPosX(float local_x);
        bool igInputFloat4(const(char)* label, float[4]*/*[4]*/ v, const(char)* format, ImGuiInputTextFlags flags);
        void igSeparator();
        void ImRect_Translate(ImRect* self, const ImVec2 d);
        void ImDrawList_PrimUnreserve(ImDrawList* self, int idx_count, int vtx_count);
        void igColorPickerOptionsPopup(const float* ref_col, ImGuiColorEditFlags flags);
        bool ImRect_IsInverted(ImRect* self);
        int igGetKeyIndex(ImGuiKey imgui_key);
        void ImGuiMetricsConfig_destroy(ImGuiMetricsConfig* self);
        void igPushItemFlag(ImGuiItemFlags option, bool enabled);
        void igScrollbar(ImGuiAxis axis);
        void igDebugNodeWindowsList(ImVector!(ImGuiWindow*)* windows, const(char)* label);
        void ImDrawList_PrimWriteVtx(ImDrawList* self, const ImVec2 pos, const ImVec2 uv, ImU32 col);
        void igSetActiveID(ImGuiID id, ImGuiWindow* window);
        bool ImGuiPayload_IsDataType(ImGuiPayload* self, const(char)* type);
        void igSetWindowSize_Vec2(const ImVec2 size, ImGuiCond cond);
        void igSetWindowSize_Str(const(char)* name, const ImVec2 size, ImGuiCond cond);
        void igSetWindowSize_WindowPtr(ImGuiWindow* window, const ImVec2 size, ImGuiCond cond);
        void ImFontGlyphRangesBuilder_BuildRanges(ImFontGlyphRangesBuilder* self, ImVector!(ImWchar)* out_ranges);
        void igTreePop();
        void igTableGetCellBgRect(ImRect* pOut, const ImGuiTable* table, int column_n);
        void ImFont_AddRemapChar(ImFont* self, ImWchar dst, ImWchar src, bool overwrite_dst);
        void igNavMoveRequestCancel();
        void igText(const(char)* fmt, ...);
        bool igCollapseButton(ImGuiID id, const ImVec2 pos);
        void ImGuiWindow_TitleBarRect(ImRect* pOut, ImGuiWindow* self);
        bool igIsItemFocused();
        void* igMemAlloc(size_t size);
        void ImGuiStackSizes_destroy(ImGuiStackSizes* self);
        bool igColorPicker3(const(char)* label, float[3]*/*[3]*/ col, ImGuiColorEditFlags flags);
        void ImGuiTextBuffer_destroy(ImGuiTextBuffer* self);
        float igGetColumnOffset(int column_index);
        void ImRect_GetSize(ImVec2* pOut, ImRect* self);
        void igSetItemUsingMouseWheel();
        bool igIsWindowCollapsed();
        void ImGuiNextItemData_ClearFlags(ImGuiNextItemData* self);
        bool igBeginCombo(const(char)* label, const(char)* preview_value, ImGuiComboFlags flags);
        void ImRect_Expand_Float(ImRect* self, const float amount);
        void ImRect_Expand_Vec2(ImRect* self, const ImVec2 amount);
        void igOpenPopup(const(char)* str_id, ImGuiPopupFlags popup_flags);
        bool igImCharIsBlankW(uint c);
        void ImFont_SetGlyphVisible(ImFont* self, ImWchar c, bool visible);
        ImGuiWindowSettings* igFindOrCreateWindowSettings(const(char)* name);
        bool igInputScalarN(const(char)* label, ImGuiDataType data_type, void* p_data, int components, const void* p_step, const void* p_step_fast, const(char)* format, ImGuiInputTextFlags flags);
        void ImDrawList_PrimQuadUV(ImDrawList* self, const ImVec2 a, const ImVec2 b, const ImVec2 c, const ImVec2 d, const ImVec2 uv_a, const ImVec2 uv_b, const ImVec2 uv_c, const ImVec2 uv_d, ImU32 col);
        void igPopID();
        void igEndTabBar();
        void igPopAllowKeyboardFocus();
        void ImDrawList_AddImage(ImDrawList* self, ImTextureID user_texture_id, const ImVec2 p_min, const ImVec2 p_max, const ImVec2 uv_min, const ImVec2 uv_max, ImU32 col);
        bool igBeginTabBar(const(char)* str_id, ImGuiTabBarFlags flags);
        float igGetCursorPosY();
        void igCalcTextSize(ImVec2* pOut, const(char)* text, const(char)* text_end, bool hide_text_after_double_hash, float wrap_width);
        void ImFont_CalcTextSizeA(ImVec2* pOut, ImFont* self, float size, float max_width, float wrap_width, const(char)* text_begin, const(char)* text_end, const char** remaining);
        void igImClamp(ImVec2* pOut, const ImVec2 v, const ImVec2 mn, ImVec2 mx);
        float igGetColumnWidth(int column_index);
        void igTableHeader(const(char)* label);
        void ImGuiPayload_Clear(ImGuiPayload* self);
        void ImGuiTextBuffer_reserve(ImGuiTextBuffer* self, int capacity);
        void ImGuiInputTextState_CursorAnimReset(ImGuiInputTextState* self);
        void ImRect_ClipWithFull(ImRect* self, const ImRect r);
        void igGetFontTexUvWhitePixel(ImVec2* pOut);
        void ImDrawList_ChannelsSplit(ImDrawList* self, int count);
        void igCalcWindowNextAutoFitSize(ImVec2* pOut, ImGuiWindow* window);
        void igPopFont();
        bool igImTriangleContainsPoint(const ImVec2 a, const ImVec2 b, const ImVec2 c, const ImVec2 p);
        void igRenderRectFilledWithHole(ImDrawList* draw_list, ImRect outer, ImRect inner, ImU32 col, float rounding);
        float igImFloor_Float(float f);
        void igImFloor_Vec2(ImVec2* pOut, const ImVec2 v);
        void ImDrawList_AddRect(ImDrawList* self, const ImVec2 p_min, const ImVec2 p_max, ImU32 col, float rounding, ImDrawFlags flags, float thickness);
        const(char)* igImParseFormatFindEnd(const(char)* format);
        void ImGuiTableColumnSettings_destroy(ImGuiTableColumnSettings* self);
        void ImGuiInputTextCallbackData_ClearSelection(ImGuiInputTextCallbackData* self);
        void igErrorCheckEndFrameRecover(ImGuiErrorLogCallback log_callback, void* user_data);
        void ImGuiTextRange_split(ImGuiTextRange* self, char separator, ImVector!(ImGuiTextRange)* outItem);
        void ImBitVector_Clear(ImBitVector* self);
        ImGuiWindowSettings* igCreateNewWindowSettings(const(char)* name);
        ImDrawListSharedData* igGetDrawListSharedData();
        bool igImFileClose(ImFileHandle file);
        bool igBeginChildEx(const(char)* name, ImGuiID id, const ImVec2 size_arg, bool border, ImGuiWindowFlags flags);
        void ImGuiNextWindowData_ClearFlags(ImGuiNextWindowData* self);
        bool ImFontGlyphRangesBuilder_GetBit(ImFontGlyphRangesBuilder* self, size_t n);
        void igImRotate(ImVec2* pOut, const ImVec2 v, float cos_a, float sin_a);
        ImGuiDir igImGetDirQuadrantFromDelta(float dx, float dy);
        void igTableMergeDrawChannels(ImGuiTable* table);
        ImFont* ImFontAtlas_AddFont(ImFontAtlas* self, const ImFontConfig* font_cfg);
        void igGetNavInputAmount2d(ImVec2* pOut, ImGuiNavDirSourceFlags dir_sources, ImGuiInputReadMode mode, float slow_factor, float fast_factor);
    }
    extern (C) @nogc nothrow {
        version (USE_GLFW) {
            import bindbc.sdl;

            void ImGui_ImplGlfw_NewFrame();
            bool ImGui_ImplGlfw_InitForOther(GLFWwindow* window, bool install_callbacks);
            bool ImGui_ImplGlfw_InitForVulkan(GLFWwindow* window, bool install_callbacks);
            void ImGui_ImplGlfw_CharCallback(GLFWwindow* window, uint c);
            bool ImGui_ImplGlfw_InitForOpenGL(GLFWwindow* window, bool install_callbacks);
            void ImGui_ImplGlfw_KeyCallback(GLFWwindow* window, int key, int scancode, int action, int mods);
            void ImGui_ImplGlfw_ScrollCallback(GLFWwindow* window, double xoffset, double yoffset);
            void ImGui_ImplGlfw_MouseButtonCallback(GLFWwindow* window, int button, int action, int mods);
            void ImGui_ImplGlfw_Shutdown();
        }
        version (USE_OpenGL3) {

            void ImGui_ImplOpenGL3_DestroyFontsTexture();
            bool ImGui_ImplOpenGL3_CreateFontsTexture();
            bool ImGui_ImplOpenGL3_CreateDeviceObjects();
            bool ImGui_ImplOpenGL3_Init(const(char)* glsl_version);
            void ImGui_ImplOpenGL3_DestroyDeviceObjects();
            void ImGui_ImplOpenGL3_NewFrame();
            void ImGui_ImplOpenGL3_Shutdown();
            void ImGui_ImplOpenGL3_RenderDrawData(ImDrawData* draw_data);
        }
        version (USE_SDL2) {
            import bindbc.sdl;

            void ImGui_ImplSDL2_Shutdown();
            bool ImGui_ImplSDL2_InitForMetal(SDL_Window* window);
            bool ImGui_ImplSDL2_InitForOpenGL(SDL_Window* window, void* sdl_gl_context);
            bool ImGui_ImplSDL2_InitForVulkan(SDL_Window* window);
            bool ImGui_ImplSDL2_InitForD3D(SDL_Window* window);
            bool ImGui_ImplSDL2_ProcessEvent(const SDL_Event* event);
            void ImGui_ImplSDL2_NewFrame(SDL_Window* window);
        }
        version (USE_OpenGL2) {

            bool ImGui_ImplOpenGL2_CreateDeviceObjects();
            bool ImGui_ImplOpenGL2_Init();
            void ImGui_ImplOpenGL2_DestroyDeviceObjects();
            void ImGui_ImplOpenGL2_NewFrame();
            void ImGui_ImplOpenGL2_RenderDrawData(ImDrawData* draw_data);
            bool ImGui_ImplOpenGL2_CreateFontsTexture();
            void ImGui_ImplOpenGL2_Shutdown();
            void ImGui_ImplOpenGL2_DestroyFontsTexture();
        }
    }
} else {
    extern (C) @nogc nothrow {
        alias pImDrawList_AddCircleFilled = void function(ImDrawList* self, const ImVec2 center, float radius, ImU32 col, int num_segments);
        alias pigEndTable = void function();
        alias pigGetForegroundDrawList_Nil = ImDrawList* function();
        alias pigGetForegroundDrawList_WindowPtr = ImDrawList* function(ImGuiWindow* window);
        alias pigGetForegroundDrawList_ViewportPtr = ImDrawList* function(ImGuiViewport* viewport);
        alias pImFontAtlas_GetGlyphRangesChineseFull = const ImWchar* function(ImFontAtlas* self);
        alias pigBringWindowToDisplayFront = void function(ImGuiWindow* window);
        alias pigInitialize = void function(ImGuiContext* context);
        alias pImFontAtlas_AddCustomRectRegular = int function(ImFontAtlas* self, int width, int height);
        alias pigIsMouseDragPastThreshold = bool function(ImGuiMouseButton button, float lock_threshold);
        alias pigSetWindowFontScale = void function(float scale);
        alias pigSliderFloat = bool function(const(char)* label, float* v, float v_min, float v_max, const(char)* format, ImGuiSliderFlags flags);
        alias pigImMax = void function(ImVec2* pOut, const ImVec2 lhs, const ImVec2 rhs);
        alias pImRect_GetTR = void function(ImVec2* pOut, ImRect* self);
        alias pigTableSetupColumn = void function(const(char)* label, ImGuiTableColumnFlags flags, float init_width_or_weight, ImGuiID user_id);
        alias pImFontAtlas_GetGlyphRangesThai = const ImWchar* function(ImFontAtlas* self);
        alias pImGuiInputTextState_ClearSelection = void function(ImGuiInputTextState* self);
        alias pImFont_GrowIndex = void function(ImFont* self, int new_size);
        alias pigClosePopupsOverWindow = void function(ImGuiWindow* ref_window, bool restore_focus_to_window_under_popup);
        alias pImFontAtlas_ClearInputData = void function(ImFontAtlas* self);
        alias pImGuiWindowSettings_destroy = void function(ImGuiWindowSettings* self);
        alias pigIsMouseDragging = bool function(ImGuiMouseButton button, float lock_threshold);
        alias pigLoadIniSettingsFromDisk = void function(const(char)* ini_filename);
        alias pigImBezierCubicCalc = void function(ImVec2* pOut, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, float t);
        alias pImGuiTextBuffer_end = const(char)* function(ImGuiTextBuffer* self);
        alias pImGuiTabBar_destroy = void function(ImGuiTabBar* self);
        alias pigSetClipboardText = void function(const(char)* text);
        alias pigRenderColorRectWithAlphaCheckerboard = void function(ImDrawList* draw_list, ImVec2 p_min, ImVec2 p_max, ImU32 fill_col, float grid_step, ImVec2 grid_off, float rounding, ImDrawFlags flags);
        alias pigFindBestWindowPosForPopup = void function(ImVec2* pOut, ImGuiWindow* window);
        alias pigRadioButton_Bool = bool function(const(char)* label, bool active);
        alias pigRadioButton_IntPtr = bool function(const(char)* label, int* v, int v_button);
        alias pImGuiTextFilter_Clear = void function(ImGuiTextFilter* self);
        alias pImRect_TranslateX = void function(ImRect* self, float dx);
        alias pigGetWindowPos = void function(ImVec2* pOut);
        alias pImGuiIO_ClearInputCharacters = void function(ImGuiIO* self);
        alias pigImBitArraySetBit = void function(ImU32* arr, int n);
        alias pImDrawDataBuilder_FlattenIntoSingleLayer = void function(ImDrawDataBuilder* self);
        alias pigRenderTextWrapped = void function(ImVec2 pos, const(char)* text, const(char)* text_end, float wrap_width);
        alias pigSpacing = void function();
        alias pImRect_TranslateY = void function(ImRect* self, float dy);
        alias pImGuiTextBuffer_c_str = const(char)* function(ImGuiTextBuffer* self);
        alias pigTabBarFindTabByID = ImGuiTabItem* function(ImGuiTabBar* tab_bar, ImGuiID tab_id);
        alias pigDataTypeApplyOpFromText = bool function(const(char)* buf, const(char)* initial_value_buf, ImGuiDataType data_type, void* p_data, const(char)* format);
        alias pImGuiInputTextState_destroy = void function(ImGuiInputTextState* self);
        alias pigGetDrawData = ImDrawData* function();
        alias pigRenderRectFilledRangeH = void function(ImDrawList* draw_list, const ImRect rect, ImU32 col, float x_start_norm, float x_end_norm, float rounding);
        alias pigPopItemWidth = void function();
        alias pigIsWindowAppearing = bool function();
        alias pigGetAllocatorFunctions = void function(ImGuiMemAllocFunc* p_alloc_func, ImGuiMemFreeFunc* p_free_func, void** p_user_data);
        alias pigImFontAtlasGetBuilderForStbTruetype = const ImFontBuilderIO* function();
        alias pigFindOrCreateColumns = ImGuiOldColumns* function(ImGuiWindow* window, ImGuiID id);
        alias pImGuiStorage_GetVoidPtr = void* function(ImGuiStorage* self, ImGuiID key);
        alias pImGuiInputTextState_GetRedoAvailCount = int function(ImGuiInputTextState* self);
        alias pigIsPopupOpen_Str = bool function(const(char)* str_id, ImGuiPopupFlags flags);
        alias pigIsPopupOpen_ID = bool function(ImGuiID id, ImGuiPopupFlags popup_flags);
        alias pigTableGetSortSpecs = ImGuiTableSortSpecs* function();
        alias pigTableDrawBorders = void function(ImGuiTable* table);
        alias pImGuiTable_ImGuiTable = ImGuiTable* function();
        alias pigInputDouble = bool function(const(char)* label, double* v, double step, double step_fast, const(char)* format, ImGuiInputTextFlags flags);
        alias pigUnindent = void function(float indent_w);
        alias pigIsDragDropPayloadBeingAccepted = bool function();
        alias pigGetFontSize = float function();
        alias pImGuiMenuColumns_DeclColumns = float function(ImGuiMenuColumns* self, float w0, float w1, float w2);
        alias pImFontAtlas_CalcCustomRectUV = void function(ImFontAtlas* self, const ImFontAtlasCustomRect* rect, ImVec2* out_uv_min, ImVec2* out_uv_max);
        alias pigGetFrameHeightWithSpacing = float function();
        alias pImDrawListSplitter_destroy = void function(ImDrawListSplitter* self);
        alias pigGetItemRectMax = void function(ImVec2* pOut);
        alias pigFocusableItemRegister = bool function(ImGuiWindow* window, ImGuiID id);
        alias pigDragInt = bool function(const(char)* label, int* v, float v_speed, int v_min, int v_max, const(char)* format, ImGuiSliderFlags flags);
        alias pigGetFont = ImFont* function();
        alias pigDragFloatRange2 = bool function(const(char)* label, float* v_current_min, float* v_current_max, float v_speed, float v_min, float v_max, const(char)* format, const(char)* format_max, ImGuiSliderFlags flags);
        alias pigTableUpdateLayout = void function(ImGuiTable* table);
        alias pigImStreolRange = const(char)* function(const(char)* str, const(char)* str_end);
        alias pImGuiStorage_Clear = void function(ImGuiStorage* self);
        alias pImGuiViewportP_UpdateWorkRect = void function(ImGuiViewportP* self);
        alias pigTableNextColumn = bool function();
        alias pImGuiWindow_GetID_Str = ImGuiID function(ImGuiWindow* self, const(char)* str, const(char)* str_end);
        alias pImGuiWindow_GetID_Ptr = ImGuiID function(ImGuiWindow* self, const void* ptr);
        alias pImGuiWindow_GetID_Int = ImGuiID function(ImGuiWindow* self, int n);
        alias pigImFontAtlasBuildPackCustomRects = void function(ImFontAtlas* atlas, void* stbrp_context_opaque);
        alias pigTableGetColumnFlags = ImGuiTableColumnFlags function(int column_n);
        alias pigIsActiveIdUsingKey = bool function(ImGuiKey key);
        alias pigSetCursorScreenPos = void function(const ImVec2 pos);
        alias pigImStristr = const(char)* function(const(char)* haystack, const(char)* haystack_end, const(char)* needle, const(char)* needle_end);
        alias pImFont_GetDebugName = const(char)* function(ImFont* self);
        alias pigBeginPopupContextWindow = bool function(const(char)* str_id, ImGuiPopupFlags popup_flags);
        alias pigBeginTable = bool function(const(char)* str_id, int column, ImGuiTableFlags flags, const ImVec2 outer_size, float inner_width);
        alias pigButtonEx = bool function(const(char)* label, const ImVec2 size_arg, ImGuiButtonFlags flags);
        alias pigTextEx = void function(const(char)* text, const(char)* text_end, ImGuiTextFlags flags);
        alias pImGuiPayload_IsPreview = bool function(ImGuiPayload* self);
        alias pigLabelTextV = void function(const(char)* label, const(char)* fmt, va_list args);
        alias pigImStrSkipBlank = const(char)* function(const(char)* str);
        alias pigPushColumnsBackground = void function();
        alias pImGuiWindow_ImGuiWindow = ImGuiWindow* function(ImGuiContext* context, const(char)* name);
        alias pigGetScrollMaxX = float function();
        alias pImBitVector_Create = void function(ImBitVector* self, int sz);
        alias pigCloseCurrentPopup = void function();
        alias pigImBitArraySetBitRange = void function(ImU32* arr, int n, int n2);
        alias pigSplitterBehavior = bool function(const ImRect bb, ImGuiID id, ImGuiAxis axis, float* size1, float* size2, float min_size1, float min_size2, float hover_extend, float hover_visibility_delay);
        alias pImGuiTableSortSpecs_ImGuiTableSortSpecs = ImGuiTableSortSpecs* function();
        alias pigGetMouseDragDelta = void function(ImVec2* pOut, ImGuiMouseButton button, float lock_threshold);
        alias pigSetWindowCollapsed_Bool = void function(bool collapsed, ImGuiCond cond);
        alias pigSetWindowCollapsed_Str = void function(const(char)* name, bool collapsed, ImGuiCond cond);
        alias pigSetWindowCollapsed_WindowPtr = void function(ImGuiWindow* window, bool collapsed, ImGuiCond cond);
        alias pigTableDrawContextMenu = void function(ImGuiTable* table);
        alias pigTextDisabled = void function(const(char)* fmt, ...);
        alias pigDebugNodeStorage = void function(ImGuiStorage* storage, const(char)* label);
        alias pigFindBestWindowPosForPopupEx = void function(ImVec2* pOut, const ImVec2 ref_pos, const ImVec2 size, ImGuiDir* last_dir, const ImRect r_outer, const ImRect r_avoid, ImGuiPopupPositionPolicy policy);
        alias pigTableSetColumnEnabled = void function(int column_n, bool enabled);
        alias pigShowUserGuide = void function();
        alias pigEndPopup = void function();
        alias pigClearActiveID = void function();
        alias pigBeginChildFrame = bool function(ImGuiID id, const ImVec2 size, ImGuiWindowFlags flags);
        alias pImGuiSettingsHandler_destroy = void function(ImGuiSettingsHandler* self);
        alias pImDrawList__ResetForNewFrame = void function(ImDrawList* self);
        alias pImGuiTextBuffer_append = void function(ImGuiTextBuffer* self, const(char)* str, const(char)* str_end);
        alias pImGuiInputTextState_GetUndoAvailCount = int function(ImGuiInputTextState* self);
        alias pigEndFrame = void function();
        alias pImGuiTableColumn_destroy = void function(ImGuiTableColumn* self);
        alias pImGuiTextRange_empty = bool function(ImGuiTextRange* self);
        alias pImGuiInputTextState_ClearText = void function(ImGuiInputTextState* self);
        alias pigIsRectVisible_Nil = bool function(const ImVec2 size);
        alias pigIsRectVisible_Vec2 = bool function(const ImVec2 rect_min, const ImVec2 rect_max);
        alias pImGuiInputTextCallbackData_HasSelection = bool function(ImGuiInputTextCallbackData* self);
        alias pigCalcWrapWidthForPos = float function(const ImVec2 pos, float wrap_pos_x);
        alias pigGetIDWithSeed = ImGuiID function(const(char)* str_id_begin, const(char)* str_id_end, ImGuiID seed);
        alias pigImUpperPowerOfTwo = int function(int v);
        alias pigIsMouseClicked = bool function(ImGuiMouseButton button, bool repeat);
        alias pigColorConvertRGBtoHSV = void function(float r, float g, float b, float* out_h, float* out_s, float* out_v);
        alias pigPushFocusScope = void function(ImGuiID id);
        alias pigSetNextWindowFocus = void function();
        alias pigGetDefaultFont = ImFont* function();
        alias pigGetClipboardText = const(char)* function();
        alias pigIsAnyItemHovered = bool function();
        alias pigTableResetSettings = void function(ImGuiTable* table);
        alias pImGuiListClipper_ImGuiListClipper = ImGuiListClipper* function();
        alias pigTableGetHoveredColumn = int function();
        alias pigImStrlenW = int function(const ImWchar* str);
        alias pigBeginPopup = bool function(const(char)* str_id, ImGuiWindowFlags flags);
        alias pigTableGetRowIndex = int function();
        alias pigImFileGetSize = ImU64 function(ImFileHandle file);
        alias pImGuiSettingsHandler_ImGuiSettingsHandler = ImGuiSettingsHandler* function();
        alias pigMenuItem_Bool = bool function(const(char)* label, const(char)* shortcut, bool selected, bool enabled);
        alias pigMenuItem_BoolPtr = bool function(const(char)* label, const(char)* shortcut, bool* p_selected, bool enabled);
        alias pigImStrTrimBlanks = void function(char* str);
        alias pImGuiStyleMod_ImGuiStyleMod_Int = ImGuiStyleMod* function(ImGuiStyleVar idx, int v);
        alias pImGuiStyleMod_ImGuiStyleMod_Float = ImGuiStyleMod* function(ImGuiStyleVar idx, float v);
        alias pImGuiStyleMod_ImGuiStyleMod_Vec2 = ImGuiStyleMod* function(ImGuiStyleVar idx, ImVec2 v);
        alias pImFontConfig_destroy = void function(ImFontConfig* self);
        alias pigBeginPopupEx = bool function(ImGuiID id, ImGuiWindowFlags extra_flags);
        alias pigImCharIsBlankA = bool function(char c);
        alias pigResetMouseDragDelta = void function(ImGuiMouseButton button);
        alias pImGuiListClipper_End = void function(ImGuiListClipper* self);
        alias pigSaveIniSettingsToDisk = void function(const(char)* ini_filename);
        alias pigDestroyContext = void function(ImGuiContext* ctx);
        alias pigSetNextWindowContentSize = void function(const ImVec2 size);
        alias pigGetWindowScrollbarRect = void function(ImRect* pOut, ImGuiWindow* window, ImGuiAxis axis);
        alias pigTableSetupScrollFreeze = void function(int cols, int rows);
        alias pImGuiTableSettings_GetColumnSettings = ImGuiTableColumnSettings* function(ImGuiTableSettings* self);
        alias pigInputTextMultiline = bool function(const(char)* label, char* buf, size_t buf_size, const ImVec2 size, ImGuiInputTextFlags flags, ImGuiInputTextCallback callback, void* user_data);
        alias pigIsClippedEx = bool function(const ImRect bb, ImGuiID id, bool clip_even_when_logged);
        alias pigGetWindowScrollbarID = ImGuiID function(ImGuiWindow* window, ImGuiAxis axis);
        alias pImGuiTextFilter_IsActive = bool function(ImGuiTextFilter* self);
        alias pImDrawListSharedData_ImDrawListSharedData = ImDrawListSharedData* function();
        alias pImFontAtlas_GetMouseCursorTexData = bool function(ImFontAtlas* self, ImGuiMouseCursor cursor, ImVec2* out_offset, ImVec2* out_size, ImVec2[2]*/*[2]*/ out_uv_border, ImVec2[2]*/*[2]*/ out_uv_fill);
        alias pigLogText = void function(const(char)* fmt, ...);
        alias pImGuiTableColumnSettings_ImGuiTableColumnSettings = ImGuiTableColumnSettings* function();
        alias pigImStrnicmp = int function(const(char)* str1, const(char)* str2, size_t count);
        alias pigColorEditOptionsPopup = void function(const float* col, ImGuiColorEditFlags flags);
        alias pigGetTextLineHeightWithSpacing = float function();
        alias pigTableFixColumnSortDirection = void function(ImGuiTable* table, ImGuiTableColumn* column);
        alias pigPushStyleVar_Float = void function(ImGuiStyleVar idx, float val);
        alias pigPushStyleVar_Vec2 = void function(ImGuiStyleVar idx, const ImVec2 val);
        alias pigIsActiveIdUsingNavInput = bool function(ImGuiNavInput input);
        alias pigGetInputTextState = ImGuiInputTextState* function(ImGuiID id);
        alias pigFindRenderedTextEnd = const(char)* function(const(char)* text, const(char)* text_end);
        alias pImFontAtlas_ClearFonts = void function(ImFontAtlas* self);
        alias pigTextColoredV = void function(const ImVec4 col, const(char)* fmt, va_list args);
        alias pigIsKeyReleased = bool function(int user_key_index);
        alias pigTabItemLabelAndCloseButton = void function(ImDrawList* draw_list, const ImRect bb, ImGuiTabItemFlags flags, ImVec2 frame_padding, const(char)* label, ImGuiID tab_id, ImGuiID close_button_id, bool is_contents_visible, bool* out_just_closed, bool* out_text_clipped);
        alias pImGuiTableColumnSortSpecs_ImGuiTableColumnSortSpecs = ImGuiTableColumnSortSpecs* function();
        alias pigLogToClipboard = void function(int auto_open_depth);
        alias pImFontAtlas_GetGlyphRangesKorean = const ImWchar* function(ImFontAtlas* self);
        alias pImFontGlyphRangesBuilder_SetBit = void function(ImFontGlyphRangesBuilder* self, size_t n);
        alias pigLogSetNextTextDecoration = void function(const(char)* prefix, const(char)* suffix);
        alias pigStyleColorsClassic = void function(ImGuiStyle* dst);
        alias pImGuiTabBar_GetTabOrder = int function(ImGuiTabBar* self, const ImGuiTabItem* tab);
        alias pigBegin = bool function(const(char)* name, bool* p_open, ImGuiWindowFlags flags);
        alias pImGuiLastItemDataBackup_ImGuiLastItemDataBackup = ImGuiLastItemDataBackup* function();
        alias pigBeginMenuBar = bool function();
        alias pigDataTypeClamp = bool function(ImGuiDataType data_type, void* p_data, const void* p_min, const void* p_max);
        alias pigButton = bool function(const(char)* label, const ImVec2 size);
        alias pImFontGlyphRangesBuilder_Clear = void function(ImFontGlyphRangesBuilder* self);
        alias pImGuiMenuColumns_destroy = void function(ImGuiMenuColumns* self);
        alias pigImStrncpy = void function(char* dst, const(char)* src, size_t count);
        alias pImGuiNextWindowData_ImGuiNextWindowData = ImGuiNextWindowData* function();
        alias pigImBezierCubicClosestPointCasteljau = void function(ImVec2* pOut, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, const ImVec2 p, float tess_tol);
        alias pigItemAdd = bool function(const ImRect bb, ImGuiID id, const ImRect* nav_bb);
        alias pigIsWindowNavFocusable = bool function(ImGuiWindow* window);
        alias pigGetScrollY = float function();
        alias pImGuiOldColumnData_ImGuiOldColumnData = ImGuiOldColumnData* function();
        alias pImRect_GetWidth = float function(ImRect* self);
        alias pigEndListBox = void function();
        alias pigGetItemStatusFlags = ImGuiItemStatusFlags function();
        alias pigPopFocusScope = void function();
        alias pigGetStyleColorVec4 = const ImVec4* function(ImGuiCol idx);
        alias pigTableFindByID = ImGuiTable* function(ImGuiID id);
        alias pigShutdown = void function(ImGuiContext* context);
        alias pigRenderText = void function(ImVec2 pos, const(char)* text, const(char)* text_end, bool hide_text_after_hash);
        alias pigTablePushBackgroundChannel = void function();
        alias pImRect_ClipWith = void function(ImRect* self, const ImRect r);
        alias pImRect_GetTL = void function(ImVec2* pOut, ImRect* self);
        alias pImDrawListSplitter_ImDrawListSplitter = ImDrawListSplitter* function();
        alias pImDrawList__CalcCircleAutoSegmentCount = int function(ImDrawList* self, float radius);
        alias pigSetWindowFocus_Nil = void function();
        alias pigSetWindowFocus_Str = void function(const(char)* name);
        alias pigInvisibleButton = bool function(const(char)* str_id, const ImVec2 size, ImGuiButtonFlags flags);
        alias pigTableSetColumnIndex = bool function(int column_n);
        alias pigRenderMouseCursor = void function(ImDrawList* draw_list, ImVec2 pos, float scale, ImGuiMouseCursor mouse_cursor, ImU32 col_fill, ImU32 col_border, ImU32 col_shadow);
        alias pigImFontAtlasBuildInit = void function(ImFontAtlas* atlas);
        alias pigTextColored = void function(const ImVec4 col, const(char)* fmt, ...);
        alias pigSliderScalar = bool function(const(char)* label, ImGuiDataType data_type, void* p_data, const void* p_min, const void* p_max, const(char)* format, ImGuiSliderFlags flags);
        alias pImDrawListSplitter_ClearFreeMemory = void function(ImDrawListSplitter* self);
        alias pImGuiStyle_ImGuiStyle = ImGuiStyle* function();
        alias pImGuiOldColumnData_destroy = void function(ImGuiOldColumnData* self);
        alias pImFontConfig_ImFontConfig = ImFontConfig* function();
        alias pigIsMouseDown = bool function(ImGuiMouseButton button);
        alias pImGuiTabBar_GetTabName = const(char)* function(ImGuiTabBar* self, const ImGuiTabItem* tab);
        alias pigDebugNodeTabBar = void function(ImGuiTabBar* tab_bar, const(char)* label);
        alias pigNewLine = void function();
        alias pigMemFree = void function(void* ptr);
        alias pigCalcTypematicRepeatAmount = int function(float t0, float t1, float repeat_delay, float repeat_rate);
        alias pigNextColumn = void function();
        alias pigRenderFrame = void function(ImVec2 p_min, ImVec2 p_max, ImU32 fill_col, bool border, float rounding);
        alias pigLogButtons = void function();
        alias pigEndTabItem = void function();
        alias pImFont_ClearOutputData = void function(ImFont* self);
        alias pImFont_ImFont = ImFont* function();
        alias pigRenderArrowPointingAt = void function(ImDrawList* draw_list, ImVec2 pos, ImVec2 half_sz, ImGuiDir direction, ImU32 col);
        alias pigVSliderFloat = bool function(const(char)* label, const ImVec2 size, float* v, float v_min, float v_max, const(char)* format, ImGuiSliderFlags flags);
        alias pigTableUpdateBorders = void function(ImGuiTable* table);
        alias pigEndGroup = void function();
        alias pigPlotLines_FloatPtr = void function(const(char)* label, const float* values, int values_count, int values_offset, const(char)* overlay_text, float scale_min, float scale_max, ImVec2 graph_size, int stride);
        alias pigPlotLines_FnFloatPtr = void function(const(char)* label, float function(void* data,int idx) values_getter, void* data, int values_count, int values_offset, const(char)* overlay_text, float scale_min, float scale_max, ImVec2 graph_size);
        alias pigGetColumnNormFromOffset = float function(const ImGuiOldColumns* columns, float offset);
        alias pigSetCurrentFont = void function(ImFont* font);
        alias pigSetItemAllowOverlap = void function();
        alias pImGuiStorage_GetVoidPtrRef = void** function(ImGuiStorage* self, ImGuiID key, void* default_val);
        alias pigCheckboxFlags_IntPtr = bool function(const(char)* label, int* flags, int flags_value);
        alias pigCheckboxFlags_UintPtr = bool function(const(char)* label, uint* flags, uint flags_value);
        alias pigCheckboxFlags_S64Ptr = bool function(const(char)* label, ImS64* flags, ImS64 flags_value);
        alias pigCheckboxFlags_U64Ptr = bool function(const(char)* label, ImU64* flags, ImU64 flags_value);
        alias pImGuiNavMoveResult_Clear = void function(ImGuiNavMoveResult* self);
        alias pImRect_destroy = void function(ImRect* self);
        alias pigImTriangleBarycentricCoords = void function(const ImVec2 a, const ImVec2 b, const ImVec2 c, const ImVec2 p, float* out_u, float* out_v, float* out_w);
        alias pigTreeNodeBehavior = bool function(ImGuiID id, ImGuiTreeNodeFlags flags, const(char)* label, const(char)* label_end);
        alias pImFontGlyphRangesBuilder_AddRanges = void function(ImFontGlyphRangesBuilder* self, const ImWchar* ranges);
        alias pigTableSetBgColor = void function(ImGuiTableBgTarget target, ImU32 color, int column_n);
        alias pImFontAtlas_GetGlyphRangesVietnamese = const ImWchar* function(ImFontAtlas* self);
        alias pImGuiContextHook_ImGuiContextHook = ImGuiContextHook* function();
        alias pigGetVersion = const(char)* function();
        alias pImDrawList_ImDrawList = ImDrawList* function(const ImDrawListSharedData* shared_data);
        alias pigRenderTextEllipsis = void function(ImDrawList* draw_list, const ImVec2 pos_min, const ImVec2 pos_max, float clip_max_x, float ellipsis_max_x, const(char)* text, const(char)* text_end, const ImVec2* text_size_if_known);
        alias pImGuiListClipper_destroy = void function(ImGuiListClipper* self);
        alias pImGuiTableSortSpecs_destroy = void function(ImGuiTableSortSpecs* self);
        alias pigPushOverrideID = void function(ImGuiID id);
        alias pigImMul = void function(ImVec2* pOut, const ImVec2 lhs, const ImVec2 rhs);
        alias pigSetScrollY_Float = void function(float scroll_y);
        alias pigSetScrollY_WindowPtr = void function(ImGuiWindow* window, float scroll_y);
        alias pImFont_CalcWordWrapPositionA = const(char)* function(ImFont* self, float scale, const(char)* text, const(char)* text_end, float wrap_width);
        alias pigSmallButton = bool function(const(char)* label);
        alias pImGuiTableColumn_ImGuiTableColumn = ImGuiTableColumn* function();
        alias pImGuiWindow_destroy = void function(ImGuiWindow* self);
        alias pigTableGetColumnResizeID = ImGuiID function(const ImGuiTable* table, int column_n, int instance_no);
        alias pigCombo_Str_arr = bool function(const(char)* label, int* current_item, const(char)** items, int items_count, int popup_max_height_in_items);
        alias pigCombo_Str = bool function(const(char)* label, int* current_item, const(char)* items_separated_by_zeros, int popup_max_height_in_items);
        alias pigCombo_FnBoolPtr = bool function(const(char)* label, int* current_item, bool function(void* data,int idx,const(char)** out_text) items_getter, void* data, int items_count, int popup_max_height_in_items);
        alias pigIsWindowChildOf = bool function(ImGuiWindow* window, ImGuiWindow* potential_parent);
        alias pImGuiWindow_CalcFontSize = float function(ImGuiWindow* self);
        alias pigTableSetColumnWidth = void function(int column_n, float width);
        alias pImDrawList_AddLine = void function(ImDrawList* self, const ImVec2 p1, const ImVec2 p2, ImU32 col, float thickness);
        alias pImDrawList_AddCircle = void function(ImDrawList* self, const ImVec2 center, float radius, ImU32 col, int num_segments, float thickness);
        alias pImGuiInputTextState_SelectAll = void function(ImGuiInputTextState* self);
        alias pigImParseFormatTrimDecorations = const(char)* function(const(char)* format, char* buf, size_t buf_size);
        alias pImGuiMetricsConfig_ImGuiMetricsConfig = ImGuiMetricsConfig* function();
        alias pImGuiTabBar_ImGuiTabBar = ImGuiTabBar* function();
        alias pImGuiViewport_GetCenter = void function(ImVec2* pOut, ImGuiViewport* self);
        alias pigDebugDrawItemRect = void function(ImU32 col);
        alias pigTreeNodeBehaviorIsOpen = bool function(ImGuiID id, ImGuiTreeNodeFlags flags);
        alias pigImTextCountUtf8BytesFromChar = int function(const(char)* in_text, const(char)* in_text_end);
        alias pigSetMouseCursor = void function(ImGuiMouseCursor cursor_type);
        alias pigBeginColumns = void function(const(char)* str_id, int count, ImGuiOldColumnFlags flags);
        alias pigGetIO = ImGuiIO* function();
        alias pigDragBehavior = bool function(ImGuiID id, ImGuiDataType data_type, void* p_v, float v_speed, const void* p_min, const void* p_max, const(char)* format, ImGuiSliderFlags flags);
        alias pigImModPositive = int function(int a, int b);
        alias pImFontAtlasCustomRect_destroy = void function(ImFontAtlasCustomRect* self);
        alias pImGuiPayload_destroy = void function(ImGuiPayload* self);
        alias pigEndMenu = void function();
        alias pigImSaturate = float function(float f);
        alias pImDrawList_PrimRect = void function(ImDrawList* self, const ImVec2 a, const ImVec2 b, ImU32 col);
        alias pigImLinearSweep = float function(float current, float target, float speed);
        alias pigUpdateMouseMovingWindowNewFrame = void function();
        alias pImDrawList_AddRectFilled = void function(ImDrawList* self, const ImVec2 p_min, const ImVec2 p_max, ImU32 col, float rounding, ImDrawFlags flags);
        alias pImGuiPopupData_destroy = void function(ImGuiPopupData* self);
        alias pigFindSettingsHandler = ImGuiSettingsHandler* function(const(char)* type_name);
        alias pigDragInt2 = bool function(const(char)* label, int[2]*/*[2]*/ v, float v_speed, int v_min, int v_max, const(char)* format, ImGuiSliderFlags flags);
        alias pigSetColorEditOptions = void function(ImGuiColorEditFlags flags);
        alias pigIsAnyMouseDown = bool function();
        alias pImGuiTextFilter_Build = void function(ImGuiTextFilter* self);
        alias pigTabItemCalcSize = void function(ImVec2* pOut, const(char)* label, bool has_close_button);
        alias pigSetNextWindowCollapsed = void function(bool collapsed, ImGuiCond cond);
        alias pigSetLastItemData = void function(ImGuiWindow* window, ImGuiID item_id, ImGuiItemStatusFlags status_flags, const ImRect item_rect);
        alias pigLogToBuffer = void function(int auto_open_depth);
        alias pigImFileLoadToMemory = void* function(const(char)* filename, const(char)* mode, size_t* out_file_size, int padding_bytes);
        alias pImFontAtlas_GetGlyphRangesCyrillic = const ImWchar* function(ImFontAtlas* self);
        alias pImGuiStyle_destroy = void function(ImGuiStyle* self);
        alias pImDrawList_destroy = void function(ImDrawList* self);
        alias pImVec4_destroy = void function(ImVec4* self);
        alias pigRenderCheckMark = void function(ImDrawList* draw_list, ImVec2 pos, ImU32 col, float sz);
        alias pigTreeNodeEx_Str = bool function(const(char)* label, ImGuiTreeNodeFlags flags);
        alias pigTreeNodeEx_StrStr = bool function(const(char)* str_id, ImGuiTreeNodeFlags flags, const(char)* fmt, ...);
        alias pigTreeNodeEx_Ptr = bool function(const void* ptr_id, ImGuiTreeNodeFlags flags, const(char)* fmt, ...);
        alias pImBitVector_SetBit = void function(ImBitVector* self, int n);
        alias pigSetColumnWidth = void function(int column_index, float width);
        alias pImGuiNavMoveResult_destroy = void function(ImGuiNavMoveResult* self);
        alias pigIsItemClicked = bool function(ImGuiMouseButton mouse_button);
        alias pigTableOpenContextMenu = void function(int column_n);
        alias pImDrawList_AddCallback = void function(ImDrawList* self, ImDrawCallback callback, void* callback_data);
        alias pigGetMousePos = void function(ImVec2* pOut);
        alias pigDataTypeCompare = int function(ImGuiDataType data_type, const void* arg_1, const void* arg_2);
        alias pigImageButtonEx = bool function(ImGuiID id, ImTextureID texture_id, const ImVec2 size, const ImVec2 uv0, const ImVec2 uv1, const ImVec2 padding, const ImVec4 bg_col, const ImVec4 tint_col);
        alias pImDrawListSharedData_SetCircleTessellationMaxError = void function(ImDrawListSharedData* self, float max_error);
        alias pigGetWindowResizeID = ImGuiID function(ImGuiWindow* window, int n);
        alias pigBullet = void function();
        alias pigTableSaveSettings = void function(ImGuiTable* table);
        alias pigTableGetBoundSettings = ImGuiTableSettings* function(ImGuiTable* table);
        alias pigGetHoveredID = ImGuiID function();
        alias pigGetWindowContentRegionMin = void function(ImVec2* pOut);
        alias pigTableHeadersRow = void function();
        alias pImDrawList_AddNgonFilled = void function(ImDrawList* self, const ImVec2 center, float radius, ImU32 col, int num_segments);
        alias pigDragScalar = bool function(const(char)* label, ImGuiDataType data_type, void* p_data, float v_speed, const void* p_min, const void* p_max, const(char)* format, ImGuiSliderFlags flags);
        alias pigSetCursorPos = void function(const ImVec2 local_pos);
        alias pigGcCompactTransientMiscBuffers = void function();
        alias pigEndColumns = void function();
        alias pigSetTooltip = void function(const(char)* fmt, ...);
        alias pigTableGetColumnName_Int = const(char)* function(int column_n);
        alias pigTableGetColumnName_TablePtr = const(char)* function(const ImGuiTable* table, int column_n);
        alias pImGuiViewportP_destroy = void function(ImGuiViewportP* self);
        alias pigBeginTabBarEx = bool function(ImGuiTabBar* tab_bar, const ImRect bb, ImGuiTabBarFlags flags);
        alias pigShadeVertsLinearColorGradientKeepAlpha = void function(ImDrawList* draw_list, int vert_start_idx, int vert_end_idx, ImVec2 gradient_p0, ImVec2 gradient_p1, ImU32 col0, ImU32 col1);
        alias pImGuiInputTextState_HasSelection = bool function(ImGuiInputTextState* self);
        alias pigCalcItemWidth = float function();
        alias pigPushItemWidth = void function(float item_width);
        alias pigScrollbarEx = bool function(const ImRect bb, ImGuiID id, ImGuiAxis axis, float* p_scroll_v, float avail_v, float contents_v, ImDrawFlags flags);
        alias pImDrawList_ChannelsMerge = void function(ImDrawList* self);
        alias pigSetAllocatorFunctions = void function(ImGuiMemAllocFunc alloc_func, ImGuiMemFreeFunc free_func, void* user_data);
        alias pImFont_FindGlyph = const ImFontGlyph* function(ImFont* self, ImWchar c);
        alias pigDebugStartItemPicker = void function();
        alias pImGuiNextWindowData_destroy = void function(ImGuiNextWindowData* self);
        alias pImGuiPayload_IsDelivery = bool function(ImGuiPayload* self);
        alias pImFontAtlas_GetGlyphRangesJapanese = const ImWchar* function(ImFontAtlas* self);
        alias pImRect_Overlaps = bool function(ImRect* self, const ImRect r);
        alias pigCaptureMouseFromApp = void function(bool want_capture_mouse_value);
        alias pigAddContextHook = ImGuiID function(ImGuiContext* context, const ImGuiContextHook* hook);
        alias pigImHashData = ImGuiID function(const void* data, size_t data_size, ImU32 seed);
        alias pImGuiInputTextCallbackData_InsertChars = void function(ImGuiInputTextCallbackData* self, int pos, const(char)* text, const(char)* text_end);
        alias pigDragFloat2 = bool function(const(char)* label, float[2]*/*[2]*/ v, float v_speed, float v_min, float v_max, const(char)* format, ImGuiSliderFlags flags);
        alias pigTreePushOverrideID = void function(ImGuiID id);
        alias pigUpdateHoveredWindowAndCaptureFlags = void function();
        alias pImFont_destroy = void function(ImFont* self);
        alias pigEndMenuBar = void function();
        alias pigGetWindowSize = void function(ImVec2* pOut);
        alias pigInputInt4 = bool function(const(char)* label, int[4]*/*[4]*/ v, ImGuiInputTextFlags flags);
        alias pigImSign_Float = float function(float x);
        alias pigImSign_double = double function(double x);
        alias pImDrawList_AddBezierQuadratic = void function(ImDrawList* self, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, ImU32 col, float thickness, int num_segments);
        alias pigGetMouseCursor = ImGuiMouseCursor function();
        alias pigIsMouseDoubleClicked = bool function(ImGuiMouseButton button);
        alias pigLabelText = void function(const(char)* label, const(char)* fmt, ...);
        alias pImDrawList_PathClear = void function(ImDrawList* self);
        alias pImDrawCmd_destroy = void function(ImDrawCmd* self);
        alias pigGetStateStorage = ImGuiStorage* function();
        alias pigInputInt2 = bool function(const(char)* label, int[2]*/*[2]*/ v, ImGuiInputTextFlags flags);
        alias pigImFileRead = ImU64 function(void* data, ImU64 size, ImU64 count, ImFileHandle file);
        alias pigImFontAtlasBuildRender32bppRectFromString = void function(ImFontAtlas* atlas, int x, int y, int w, int h, const(char)* in_str, char in_marker_char, uint in_marker_pixel_value);
        alias pImGuiOldColumns_destroy = void function(ImGuiOldColumns* self);
        alias pigSetNextWindowScroll = void function(const ImVec2 scroll);
        alias pigGetFrameHeight = float function();
        alias pigImFileWrite = ImU64 function(const void* data, ImU64 size, ImU64 count, ImFileHandle file);
        alias pigInputText = bool function(const(char)* label, char* buf, size_t buf_size, ImGuiInputTextFlags flags, ImGuiInputTextCallback callback, void* user_data);
        alias pigTreeNodeExV_Str = bool function(const(char)* str_id, ImGuiTreeNodeFlags flags, const(char)* fmt, va_list args);
        alias pigTreeNodeExV_Ptr = bool function(const void* ptr_id, ImGuiTreeNodeFlags flags, const(char)* fmt, va_list args);
        alias pigTableSetColumnSortDirection = void function(int column_n, ImGuiSortDirection sort_direction, bool append_to_sort_specs);
        alias pigIsAnyItemFocused = bool function();
        alias pImDrawDataBuilder_Clear = void function(ImDrawDataBuilder* self);
        alias pImVec2ih_ImVec2ih_Nil = ImVec2ih* function();
        alias pImVec2ih_ImVec2ih_short = ImVec2ih* function(short _x, short _y);
        alias pImVec2ih_ImVec2ih_Vec2 = ImVec2ih* function(const ImVec2 rhs);
        alias pigPopStyleColor = void function(int count);
        alias pImVec1_ImVec1_Nil = ImVec1* function();
        alias pImVec1_ImVec1_Float = ImVec1* function(float _x);
        alias pigCalcItemSize = void function(ImVec2* pOut, ImVec2 size, float default_w, float default_h);
        alias pImFontAtlasCustomRect_IsPacked = bool function(ImFontAtlasCustomRect* self);
        alias pigColorEdit4 = bool function(const(char)* label, float[4]*/*[4]*/ col, ImGuiColorEditFlags flags);
        alias pigPlotEx = int function(ImGuiPlotType plot_type, const(char)* label, float function(void* data,int idx) values_getter, void* data, int values_count, int values_offset, const(char)* overlay_text, float scale_min, float scale_max, ImVec2 frame_size);
        alias pigGetCursorStartPos = void function(ImVec2* pOut);
        alias pImGuiInputTextCallbackData_destroy = void function(ImGuiInputTextCallbackData* self);
        alias pImFontAtlas_IsBuilt = bool function(ImFontAtlas* self);
        alias pImGuiTextBuffer_begin = const(char)* function(ImGuiTextBuffer* self);
        alias pImGuiTable_destroy = void function(ImGuiTable* self);
        alias pImGuiWindow_GetIDNoKeepAlive_Str = ImGuiID function(ImGuiWindow* self, const(char)* str, const(char)* str_end);
        alias pImGuiWindow_GetIDNoKeepAlive_Ptr = ImGuiID function(ImGuiWindow* self, const void* ptr);
        alias pImGuiWindow_GetIDNoKeepAlive_Int = ImGuiID function(ImGuiWindow* self, int n);
        alias pImFont_BuildLookupTable = void function(ImFont* self);
        alias pImGuiTextBuffer_appendfv = void function(ImGuiTextBuffer* self, const(char)* fmt, va_list args);
        alias pImVec4_ImVec4_Nil = ImVec4* function();
        alias pImVec4_ImVec4_Float = ImVec4* function(float _x, float _y, float _z, float _w);
        alias pigClearIniSettings = void function();
        alias pigImTextCountCharsFromUtf8 = int function(const(char)* in_text, const(char)* in_text_end);
        alias pImDrawList_PathLineToMergeDuplicate = void function(ImDrawList* self, const ImVec2 pos);
        alias pImGuiIO_ImGuiIO = ImGuiIO* function();
        alias pigDragInt4 = bool function(const(char)* label, int[4]*/*[4]*/ v, float v_speed, int v_min, int v_max, const(char)* format, ImGuiSliderFlags flags);
        alias pigBeginDragDropTarget = bool function();
        alias pigTablePopBackgroundChannel = void function();
        alias pImGuiTextBuffer_clear = void function(ImGuiTextBuffer* self);
        alias pigImStricmp = int function(const(char)* str1, const(char)* str2);
        alias pigMarkItemEdited = void function(ImGuiID id);
        alias pigIsWindowFocused = bool function(ImGuiFocusedFlags flags);
        alias pigTableSettingsCreate = ImGuiTableSettings* function(ImGuiID id, int columns_count);
        alias pImGuiIO_AddInputCharactersUTF8 = void function(ImGuiIO* self, const(char)* str);
        alias pImGuiTableSettings_destroy = void function(ImGuiTableSettings* self);
        alias pigIsWindowAbove = bool function(ImGuiWindow* potential_above, ImGuiWindow* potential_below);
        alias pImDrawList__PathArcToN = void function(ImDrawList* self, const ImVec2 center, float radius, float a_min, float a_max, int num_segments);
        alias pigColorTooltip = void function(const(char)* text, const float* col, ImGuiColorEditFlags flags);
        alias pigSetCurrentContext = void function(ImGuiContext* ctx);
        alias pigImTriangleClosestPoint = void function(ImVec2* pOut, const ImVec2 a, const ImVec2 b, const ImVec2 c, const ImVec2 p);
        alias pigSliderInt4 = bool function(const(char)* label, int[4]*/*[4]*/ v, int v_min, int v_max, const(char)* format, ImGuiSliderFlags flags);
        alias pigGetItemRectMin = void function(ImVec2* pOut);
        alias pigTableUpdateColumnsWeightFromWidth = void function(ImGuiTable* table);
        alias pImDrawList_PrimReserve = void function(ImDrawList* self, int idx_count, int vtx_count);
        alias pImGuiMenuColumns_ImGuiMenuColumns = ImGuiMenuColumns* function();
        alias pImDrawList_AddRectFilledMultiColor = void function(ImDrawList* self, const ImVec2 p_min, const ImVec2 p_max, ImU32 col_upr_left, ImU32 col_upr_right, ImU32 col_bot_right, ImU32 col_bot_left);
        alias pigImPow_Float = float function(float x, float y);
        alias pigImPow_double = double function(double x, double y);
        alias pigSeparatorEx = void function(ImGuiSeparatorFlags flags);
        alias pigSetStateStorage = void function(ImGuiStorage* storage);
        alias pImGuiStorage_SetAllInt = void function(ImGuiStorage* self, int val);
        alias pImGuiListClipper_Step = bool function(ImGuiListClipper* self);
        alias pImGuiOnceUponAFrame_destroy = void function(ImGuiOnceUponAFrame* self);
        alias pImGuiInputTextCallbackData_DeleteChars = void function(ImGuiInputTextCallbackData* self, int pos, int bytes_count);
        alias pigImFontAtlasBuildSetupFont = void function(ImFontAtlas* atlas, ImFont* font, ImFontConfig* font_config, float ascent, float descent);
        alias pImGuiTextBuffer_empty = bool function(ImGuiTextBuffer* self);
        alias pigShowDemoWindow = void function(bool* p_open);
        alias pImGuiTextRange_destroy = void function(ImGuiTextRange* self);
        alias pImGuiStorage_SetVoidPtr = void function(ImGuiStorage* self, ImGuiID key, void* val);
        alias pigImInvLength = float function(const ImVec2 lhs, float fail_value);
        alias pigGetFocusScope = ImGuiID function();
        alias pigCloseButton = bool function(ImGuiID id, const ImVec2 pos);
        alias pigTableSettingsInstallHandler = void function(ImGuiContext* context);
        alias pImDrawList_PushTextureID = void function(ImDrawList* self, ImTextureID texture_id);
        alias pImDrawList_PathLineTo = void function(ImDrawList* self, const ImVec2 pos);
        alias pigSetWindowHitTestHole = void function(ImGuiWindow* window, const ImVec2 pos, const ImVec2 size);
        alias pImRect_Add_Vec2 = void function(ImRect* self, const ImVec2 p);
        alias pImRect_Add_Rect = void function(ImRect* self, const ImRect r);
        alias pigShowMetricsWindow = void function(bool* p_open);
        alias pImDrawList__PopUnusedDrawCmd = void function(ImDrawList* self);
        alias pImDrawList_AddImageRounded = void function(ImDrawList* self, ImTextureID user_texture_id, const ImVec2 p_min, const ImVec2 p_max, const ImVec2 uv_min, const ImVec2 uv_max, ImU32 col, float rounding, ImDrawFlags flags);
        alias pImGuiStyleMod_destroy = void function(ImGuiStyleMod* self);
        alias pImGuiStorage_BuildSortByKey = void function(ImGuiStorage* self);
        alias pigTableSetupDrawChannels = void function(ImGuiTable* table);
        alias pImDrawList_PathRect = void function(ImDrawList* self, const ImVec2 rect_min, const ImVec2 rect_max, float rounding, ImDrawFlags flags);
        alias pigInputTextEx = bool function(const(char)* label, const(char)* hint, char* buf, int buf_size, const ImVec2 size_arg, ImGuiInputTextFlags flags, ImGuiInputTextCallback callback, void* user_data);
        alias pigColorEdit3 = bool function(const(char)* label, float[3]*/*[3]*/ col, ImGuiColorEditFlags flags);
        alias pImColor_destroy = void function(ImColor* self);
        alias pigIsItemToggledSelection = bool function();
        alias pigTabItemEx = bool function(ImGuiTabBar* tab_bar, const(char)* label, bool* p_open, ImGuiTabItemFlags flags);
        alias pigIsKeyPressedMap = bool function(ImGuiKey key, bool repeat);
        alias pigLogFinish = void function();
        alias pigGetItemRectSize = void function(ImVec2* pOut);
        alias pigImParseFormatFindStart = const(char)* function(const(char)* format);
        alias pigDragScalarN = bool function(const(char)* label, ImGuiDataType data_type, void* p_data, int components, float v_speed, const void* p_min, const void* p_max, const(char)* format, ImGuiSliderFlags flags);
        alias pImDrawData_ImDrawData = ImDrawData* function();
        alias pigImDot = float function(const ImVec2 a, const ImVec2 b);
        alias pigMarkIniSettingsDirty_Nil = void function();
        alias pigMarkIniSettingsDirty_WindowPtr = void function(ImGuiWindow* window);
        alias pigTableGetColumnCount = int function();
        alias pigGetWindowWidth = float function();
        alias pigBulletTextV = void function(const(char)* fmt, va_list args);
        alias pigPushTextWrapPos = void function(float wrap_local_pos_x);
        alias pImDrawListSplitter_SetCurrentChannel = void function(ImDrawListSplitter* self, ImDrawList* draw_list, int channel_idx);
        alias pImGuiStorage_SetBool = void function(ImGuiStorage* self, ImGuiID key, bool val);
        alias pigAlignTextToFramePadding = void function();
        alias pigIsWindowHovered = bool function(ImGuiHoveredFlags flags);
        alias pImRect_GetCenter = void function(ImVec2* pOut, ImRect* self);
        alias pigGetWindowContentRegionWidth = float function();
        alias pImDrawList_PathArcTo = void function(ImDrawList* self, const ImVec2 center, float radius, float a_min, float a_max, int num_segments);
        alias pigIsAnyItemActive = bool function();
        alias pigStyleColorsDark = void function(ImGuiStyle* dst);
        alias pigGetTreeNodeToLabelSpacing = float function();
        alias pigSameLine = void function(float offset_from_start_x, float spacing);
        alias pigTabBarQueueReorder = void function(ImGuiTabBar* tab_bar, const ImGuiTabItem* tab, int dir);
        alias pigDummy = void function(const ImVec2 size);
        alias pigGetItemID = ImGuiID function();
        alias pigImageButton = bool function(ImTextureID user_texture_id, const ImVec2 size, const ImVec2 uv0, const ImVec2 uv1, int frame_padding, const ImVec4 bg_col, const ImVec4 tint_col);
        alias pigGetWindowContentRegionMax = void function(ImVec2* pOut);
        alias pigGetKeyPressedAmount = int function(int key_index, float repeat_delay, float rate);
        alias pigRenderTextClipped = void function(const ImVec2 pos_min, const ImVec2 pos_max, const(char)* text, const(char)* text_end, const ImVec2* text_size_if_known, const ImVec2 alignment, const ImRect* clip_rect);
        alias pigImIsPowerOfTwo_Int = bool function(int v);
        alias pigImIsPowerOfTwo_U64 = bool function(ImU64 v);
        alias pigSetNextWindowSizeConstraints = void function(const ImVec2 size_min, const ImVec2 size_max, ImGuiSizeCallback custom_callback, void* custom_callback_data);
        alias pigTableGcCompactTransientBuffers = void function(ImGuiTable* table);
        alias pImFont_FindGlyphNoFallback = const ImFontGlyph* function(ImFont* self, ImWchar c);
        alias pigShowStyleSelector = bool function(const(char)* label);
        alias pigFocusableItemUnregister = void function(ImGuiWindow* window);
        alias pigNavMoveRequestForward = void function(ImGuiDir move_dir, ImGuiDir clip_dir, const ImRect bb_rel, ImGuiNavMoveFlags move_flags);
        alias pigNavInitWindow = void function(ImGuiWindow* window, bool force_reinit);
        alias pigImFileOpen = ImFileHandle function(const(char)* filename, const(char)* mode);
        alias pigEndDragDropTarget = void function();
        alias pImGuiWindowSettings_ImGuiWindowSettings = ImGuiWindowSettings* function();
        alias pImDrawListSharedData_destroy = void function(ImDrawListSharedData* self);
        alias pImFontAtlas_Build = bool function(ImFontAtlas* self);
        alias pigSetScrollFromPosX_Float = void function(float local_x, float center_x_ratio);
        alias pigSetScrollFromPosX_WindowPtr = void function(ImGuiWindow* window, float local_x, float center_x_ratio);
        alias pigIsKeyPressed = bool function(int user_key_index, bool repeat);
        alias pigEndTooltip = void function();
        alias pigFindWindowSettings = ImGuiWindowSettings* function(ImGuiID id);
        alias pigDebugRenderViewportThumbnail = void function(ImDrawList* draw_list, ImGuiViewportP* viewport, const ImRect bb);
        alias pigKeepAliveID = void function(ImGuiID id);
        alias pigGetColumnOffsetFromNorm = float function(const ImGuiOldColumns* columns, float offset_norm);
        alias pImFont_IsLoaded = bool function(ImFont* self);
        alias pigDebugNodeDrawCmdShowMeshAndBoundingBox = void function(ImDrawList* out_draw_list, const ImDrawList* draw_list, const ImDrawCmd* draw_cmd, bool show_mesh, bool show_aabb);
        alias pigBeginDragDropSource = bool function(ImGuiDragDropFlags flags);
        alias pImBitVector_ClearBit = void function(ImBitVector* self, int n);
        alias pImDrawDataBuilder_GetDrawListCount = int function(ImDrawDataBuilder* self);
        alias pigGetCursorPosX = float function();
        alias pigSetScrollFromPosY_Float = void function(float local_y, float center_y_ratio);
        alias pigSetScrollFromPosY_WindowPtr = void function(ImGuiWindow* window, float local_y, float center_y_ratio);
        alias pigColorButton = bool function(const(char)* desc_id, const ImVec4 col, ImGuiColorEditFlags flags, ImVec2 size);
        alias pigAcceptDragDropPayload = const ImGuiPayload* function(const(char)* type, ImGuiDragDropFlags flags);
        alias pImDrawList_PopClipRect = void function(ImDrawList* self);
        alias pigPushFont = void function(ImFont* font);
        alias pigGetScrollMaxY = float function();
        alias pImGuiStoragePair_ImGuiStoragePair_Int = ImGuiStoragePair* function(ImGuiID _key, int _val_i);
        alias pImGuiStoragePair_ImGuiStoragePair_Float = ImGuiStoragePair* function(ImGuiID _key, float _val_f);
        alias pImGuiStoragePair_ImGuiStoragePair_Ptr = ImGuiStoragePair* function(ImGuiID _key, void* _val_p);
        alias pigEndMainMenuBar = void function();
        alias pImGuiViewportP_GetMainRect = void function(ImRect* pOut, ImGuiViewportP* self);
        alias pImRect_GetArea = float function(ImRect* self);
        alias pigIsItemActive = bool function();
        alias pigShowAboutWindow = void function(bool* p_open);
        alias pigSetNextItemWidth = void function(float item_width);
        alias pigImStrchrRange = const(char)* function(const(char)* str_begin, const(char)* str_end, char c);
        alias pigGetContentRegionAvail = void function(ImVec2* pOut);
        alias pImGuiPayload_ImGuiPayload = ImGuiPayload* function();
        alias pigCheckbox = bool function(const(char)* label, bool* v);
        alias pImGuiTextRange_ImGuiTextRange_Nil = ImGuiTextRange* function();
        alias pImGuiTextRange_ImGuiTextRange_Str = ImGuiTextRange* function(const(char)* _b, const(char)* _e);
        alias pImFontAtlas_destroy = void function(ImFontAtlas* self);
        alias pImGuiMenuColumns_Update = void function(ImGuiMenuColumns* self, int count, float spacing, bool clear);
        alias pigGcCompactTransientWindowBuffers = void function(ImGuiWindow* window);
        alias pigTableSortSpecsBuild = void function(ImGuiTable* table);
        alias pigNavMoveRequestTryWrapping = void function(ImGuiWindow* window, ImGuiNavMoveFlags move_flags);
        alias pigGetCurrentWindow = ImGuiWindow* function();
        alias pigPushStyleColor_U32 = void function(ImGuiCol idx, ImU32 col);
        alias pigPushStyleColor_Vec4 = void function(ImGuiCol idx, const ImVec4 col);
        alias pImVec2_destroy = void function(ImVec2* self);
        alias pigTableBeginRow = void function(ImGuiTable* table);
        alias pigGetID_Str = ImGuiID function(const(char)* str_id);
        alias pigGetID_StrStr = ImGuiID function(const(char)* str_id_begin, const(char)* str_id_end);
        alias pigGetID_Ptr = ImGuiID function(const void* ptr_id);
        alias pigSetDragDropPayload = bool function(const(char)* type, const void* data, size_t sz, ImGuiCond cond);
        alias pigImFontAtlasBuildMultiplyCalcLookupTable = void function(char[256]*/*[256]*/ out_table, float in_multiply_factor);
        alias pImFontAtlas_ImFontAtlas = ImFontAtlas* function();
        alias pImGuiMenuColumns_CalcExtraSpace = float function(ImGuiMenuColumns* self, float avail_w);
        alias pigGetContentRegionMax = void function(ImVec2* pOut);
        alias pigBeginGroup = void function();
        alias pigActivateItem = void function(ImGuiID id);
        alias pigPopStyleVar = void function(int count);
        alias pImDrawList_PushClipRectFullScreen = void function(ImDrawList* self);
        alias pImRect_Contains_Vec2 = bool function(ImRect* self, const ImVec2 p);
        alias pImRect_Contains_Rect = bool function(ImRect* self, const ImRect r);
        alias pigEndChildFrame = void function();
        alias pigSetColumnOffset = void function(int column_index, float offset_x);
        alias pigSetKeyboardFocusHere = void function(int offset);
        alias pigLoadIniSettingsFromMemory = void function(const(char)* ini_data, size_t ini_size);
        alias pigGetBackgroundDrawList_Nil = ImDrawList* function();
        alias pigGetBackgroundDrawList_ViewportPtr = ImDrawList* function(ImGuiViewport* viewport);
        alias pigSetNextWindowSize = void function(const ImVec2 size, ImGuiCond cond);
        alias pigInputFloat3 = bool function(const(char)* label, float[3]*/*[3]*/ v, const(char)* format, ImGuiInputTextFlags flags);
        alias pigIndent = void function(float indent_w);
        alias pigTableBeginApplyRequests = void function(ImGuiTable* table);
        alias pigIsKeyDown = bool function(int user_key_index);
        alias pigTextUnformatted = void function(const(char)* text, const(char)* text_end);
        alias pigTextV = void function(const(char)* fmt, va_list args);
        alias pigImLengthSqr_Vec2 = float function(const ImVec2 lhs);
        alias pigImLengthSqr_Vec4 = float function(const ImVec4 lhs);
        alias pImGuiTextFilter_Draw = bool function(ImGuiTextFilter* self, const(char)* label, float width);
        alias pigFocusWindow = void function(ImGuiWindow* window);
        alias pigPushClipRect = void function(const ImVec2 clip_rect_min, const ImVec2 clip_rect_max, bool intersect_with_current_clip_rect);
        alias pImGuiViewportP_ImGuiViewportP = ImGuiViewportP* function();
        alias pigBeginMainMenuBar = bool function();
        alias pImRect_GetBR = void function(ImVec2* pOut, ImRect* self);
        alias pigCollapsingHeader_TreeNodeFlags = bool function(const(char)* label, ImGuiTreeNodeFlags flags);
        alias pigCollapsingHeader_BoolPtr = bool function(const(char)* label, bool* p_visible, ImGuiTreeNodeFlags flags);
        alias pigGetCurrentWindowRead = ImGuiWindow* function();
        alias pImDrawList__PathArcToFastEx = void function(ImDrawList* self, const ImVec2 center, float radius, int a_min_sample, int a_max_sample, int a_step);
        alias pigSliderInt3 = bool function(const(char)* label, int[3]*/*[3]*/ v, int v_min, int v_max, const(char)* format, ImGuiSliderFlags flags);
        alias pigGetItemsFlags = ImGuiItemFlags function();
        alias pImGuiTableSettings_ImGuiTableSettings = ImGuiTableSettings* function();
        alias pigImFormatString = int function(char* buf, size_t buf_size, const(char)* fmt, ...);
        alias pigTabItemButton = bool function(const(char)* label, ImGuiTabItemFlags flags);
        alias pigIsMouseReleased = bool function(ImGuiMouseButton button);
        alias pImGuiInputTextState_CursorClamp = void function(ImGuiInputTextState* self);
        alias pigRemoveContextHook = void function(ImGuiContext* context, ImGuiID hook_to_remove);
        alias pImFontAtlasCustomRect_ImFontAtlasCustomRect = ImFontAtlasCustomRect* function();
        alias pImGuiIO_AddInputCharacter = void function(ImGuiIO* self, uint c);
        alias pigTabBarProcessReorder = bool function(ImGuiTabBar* tab_bar);
        alias pigGetNavInputAmount = float function(ImGuiNavInput n, ImGuiInputReadMode mode);
        alias pigClearDragDrop = void function();
        alias pigGetTextLineHeight = float function();
        alias pImDrawList_AddBezierCubic = void function(ImDrawList* self, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, ImU32 col, float thickness, int num_segments);
        alias pigDataTypeApplyOp = void function(ImGuiDataType data_type, int op, void* output, const void* arg_1, const void* arg_2);
        alias pImDrawList_AddQuadFilled = void function(ImDrawList* self, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, ImU32 col);
        alias pigSetNextWindowBgAlpha = void function(float alpha);
        alias pImGuiInputTextCallbackData_SelectAll = void function(ImGuiInputTextCallbackData* self);
        alias pImGuiNextItemData_ImGuiNextItemData = ImGuiNextItemData* function();
        alias pigLogRenderedText = void function(const ImVec2* ref_pos, const(char)* text, const(char)* text_end);
        alias pigBeginMenu = bool function(const(char)* label, bool enabled);
        alias pImGuiStorage_GetIntRef = int* function(ImGuiStorage* self, ImGuiID key, int default_val);
        alias pigImTextCountUtf8BytesFromStr = int function(const ImWchar* in_text, const ImWchar* in_text_end);
        alias pigEndCombo = void function();
        alias pigIsNavInputTest = bool function(ImGuiNavInput n, ImGuiInputReadMode rm);
        alias pigImage = void function(ImTextureID user_texture_id, const ImVec2 size, const ImVec2 uv0, const ImVec2 uv1, const ImVec4 tint_col, const ImVec4 border_col);
        alias pImDrawList_AddPolyline = void function(ImDrawList* self, const ImVec2* points, int num_points, ImU32 col, ImDrawFlags flags, float thickness);
        alias pigTreeNode_Str = bool function(const(char)* label);
        alias pigTreeNode_StrStr = bool function(const(char)* str_id, const(char)* fmt, ...);
        alias pigTreeNode_Ptr = bool function(const void* ptr_id, const(char)* fmt, ...);
        alias pigPopClipRect = void function();
        alias pImDrawList_PushClipRect = void function(ImDrawList* self, ImVec2 clip_rect_min, ImVec2 clip_rect_max, bool intersect_with_current_clip_rect);
        alias pigImBitArrayClearBit = void function(ImU32* arr, int n);
        alias pigArrowButtonEx = bool function(const(char)* str_id, ImGuiDir dir, ImVec2 size_arg, ImGuiButtonFlags flags);
        alias pigSelectable_Bool = bool function(const(char)* label, bool selected, ImGuiSelectableFlags flags, const ImVec2 size);
        alias pigSelectable_BoolPtr = bool function(const(char)* label, bool* p_selected, ImGuiSelectableFlags flags, const ImVec2 size);
        alias pigTableSetColumnWidthAutoSingle = void function(ImGuiTable* table, int column_n);
        alias pigBeginTooltipEx = void function(ImGuiWindowFlags extra_flags, ImGuiTooltipFlags tooltip_flags);
        alias pigGetFocusID = ImGuiID function();
        alias pImDrawData_DeIndexAllBuffers = void function(ImDrawData* self);
        alias pImDrawCmd_ImDrawCmd = ImDrawCmd* function();
        alias pImDrawData_ScaleClipRects = void function(ImDrawData* self, const ImVec2 fb_scale);
        alias pigSetNextItemOpen = void function(bool is_open, ImGuiCond cond);
        alias pigDataTypeFormatString = int function(char* buf, int buf_size, ImGuiDataType data_type, const void* p_data, const(char)* format);
        alias pigTabItemBackground = void function(ImDrawList* draw_list, const ImRect bb, ImGuiTabItemFlags flags, ImU32 col);
        alias pImDrawList_AddTriangle = void function(ImDrawList* self, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, ImU32 col, float thickness);
        alias pigLogToFile = void function(int auto_open_depth, const(char)* filename);
        alias pImGuiContextHook_destroy = void function(ImGuiContextHook* self);
        alias pigTempInputIsActive = bool function(ImGuiID id);
        alias pImGuiNextItemData_destroy = void function(ImGuiNextItemData* self);
        alias pigGetMergedKeyModFlags = ImGuiKeyModFlags function();
        alias pigDebugNodeWindowSettings = void function(ImGuiWindowSettings* settings);
        alias pImRect_ToVec4 = void function(ImVec4* pOut, ImRect* self);
        alias pigTableGcCompactSettings = void function();
        alias pigPushMultiItemsWidths = void function(int components, float width_full);
        alias pigCreateContext = ImGuiContext* function(ImFontAtlas* shared_font_atlas);
        alias pigTableNextRow = void function(ImGuiTableRowFlags row_flags, float min_row_height);
        alias pImGuiStackSizes_CompareWithCurrentState = void function(ImGuiStackSizes* self);
        alias pImColor_ImColor_Nil = ImColor* function();
        alias pImColor_ImColor_Int = ImColor* function(int r, int g, int b, int a);
        alias pImColor_ImColor_U32 = ImColor* function(ImU32 rgba);
        alias pImColor_ImColor_Float = ImColor* function(float r, float g, float b, float a);
        alias pImColor_ImColor_Vec4 = ImColor* function(const ImVec4 col);
        alias pigTableGetMaxColumnWidth = float function(const ImGuiTable* table, int column_n);
        alias pImDrawList__ClearFreeMemory = void function(ImDrawList* self);
        alias pigSetNavID = void function(ImGuiID id, int nav_layer, ImGuiID focus_scope_id, const ImRect rect_rel);
        alias pigGetWindowDrawList = ImDrawList* function();
        alias pImRect_GetBL = void function(ImVec2* pOut, ImRect* self);
        alias pigTableGetHeaderRowHeight = float function();
        alias pigIsMousePosValid = bool function(const ImVec2* mouse_pos);
        alias pImGuiStorage_GetFloat = float function(ImGuiStorage* self, ImGuiID key, float default_val);
        alias pigTableEndCell = void function(ImGuiTable* table);
        alias pigSliderFloat4 = bool function(const(char)* label, float[4]*/*[4]*/ v, float v_min, float v_max, const(char)* format, ImGuiSliderFlags flags);
        alias pigIsItemDeactivatedAfterEdit = bool function();
        alias pigPlotHistogram_FloatPtr = void function(const(char)* label, const float* values, int values_count, int values_offset, const(char)* overlay_text, float scale_min, float scale_max, ImVec2 graph_size, int stride);
        alias pigPlotHistogram_FnFloatPtr = void function(const(char)* label, float function(void* data,int idx) values_getter, void* data, int values_count, int values_offset, const(char)* overlay_text, float scale_min, float scale_max, ImVec2 graph_size);
        alias pigIsItemEdited = bool function();
        alias pigShowStyleEditor = void function(ImGuiStyle* reference);
        alias pigTextWrappedV = void function(const(char)* fmt, va_list args);
        alias pigTableBeginCell = void function(ImGuiTable* table, int column_n);
        alias pigTableGetColumnNextSortDirection = ImGuiSortDirection function(ImGuiTableColumn* column);
        alias pImGuiLastItemDataBackup_destroy = void function(ImGuiLastItemDataBackup* self);
        alias pImGuiTextBuffer_appendf = void function(ImGuiTextBuffer* self, const(char)* fmt, ...);
        alias pImFontAtlas_AddCustomRectFontGlyph = int function(ImFontAtlas* self, ImFont* font, ImWchar id, int width, int height, float advance_x, const ImVec2 offset);
        alias pigDebugCheckVersionAndDataLayout = bool function(const(char)* version_str, size_t sz_io, size_t sz_style, size_t sz_vec2, size_t sz_vec4, size_t sz_drawvert, size_t sz_drawidx);
        alias pigImAlphaBlendColors = ImU32 function(ImU32 col_a, ImU32 col_b);
        alias pImGuiStorage_GetBoolRef = bool* function(ImGuiStorage* self, ImGuiID key, bool default_val);
        alias pigBeginPopupContextVoid = bool function(const(char)* str_id, ImGuiPopupFlags popup_flags);
        alias pigSetScrollX_Float = void function(float scroll_x);
        alias pigSetScrollX_WindowPtr = void function(ImGuiWindow* window, float scroll_x);
        alias pigRenderNavHighlight = void function(const ImRect bb, ImGuiID id, ImGuiNavHighlightFlags flags);
        alias pigBringWindowToFocusFront = void function(ImGuiWindow* window);
        alias pigSliderInt = bool function(const(char)* label, int* v, int v_min, int v_max, const(char)* format, ImGuiSliderFlags flags);
        alias pigUpdateMouseMovingWindowEndFrame = void function();
        alias pigInputTextWithHint = bool function(const(char)* label, const(char)* hint, char* buf, size_t buf_size, ImGuiInputTextFlags flags, ImGuiInputTextCallback callback, void* user_data);
        alias pigGetContentRegionMaxAbs = void function(ImVec2* pOut);
        alias pigIsMouseHoveringRect = bool function(const ImVec2 r_min, const ImVec2 r_max, bool clip);
        alias pImGuiLastItemDataBackup_Backup = void function(ImGuiLastItemDataBackup* self);
        alias pigImTextStrFromUtf8 = int function(ImWchar* buf, int buf_size, const(char)* in_text, const(char)* in_text_end, const char** in_remaining);
        alias pigIsActiveIdUsingNavDir = bool function(ImGuiDir dir);
        alias pImGuiListClipper_Begin = void function(ImGuiListClipper* self, int items_count, float items_height);
        alias pigStartMouseMovingWindow = void function(ImGuiWindow* window);
        alias pigSliderInt2 = bool function(const(char)* label, int[2]*/*[2]*/ v, int v_min, int v_max, const(char)* format, ImGuiSliderFlags flags);
        alias pigIsItemHovered = bool function(ImGuiHoveredFlags flags);
        alias pigTableEndRow = void function(ImGuiTable* table);
        alias pImGuiIO_destroy = void function(ImGuiIO* self);
        alias pigEndDragDropSource = void function();
        alias pImGuiStackSizes_SetToCurrentState = void function(ImGuiStackSizes* self);
        alias pigGetDragDropPayload = const ImGuiPayload* function();
        alias pigPopButtonRepeat = void function();
        alias pImGuiStorage_SetInt = void function(ImGuiStorage* self, ImGuiID key, int val);
        alias pImGuiWindow_MenuBarRect = void function(ImRect* pOut, ImGuiWindow* self);
        alias pImGuiStorage_GetInt = int function(ImGuiStorage* self, ImGuiID key, int default_val);
        alias pigShowFontSelector = void function(const(char)* label);
        alias pigImMin = void function(ImVec2* pOut, const ImVec2 lhs, const ImVec2 rhs);
        alias pigPushButtonRepeat = void function(bool repeat);
        alias pigTableSetColumnWidthAutoAll = void function(ImGuiTable* table);
        alias pigImAbs_Float = float function(float x);
        alias pigImAbs_double = double function(double x);
        alias pImGuiWindow_Rect = void function(ImRect* pOut, ImGuiWindow* self);
        alias pImGuiViewportP_GetWorkRect = void function(ImRect* pOut, ImGuiViewportP* self);
        alias pImRect_Floor = void function(ImRect* self);
        alias pigTreePush_Str = void function(const(char)* str_id);
        alias pigTreePush_Ptr = void function(const void* ptr_id);
        alias pigColorConvertFloat4ToU32 = ImU32 function(const ImVec4 inItem);
        alias pigGetStyle = ImGuiStyle* function();
        alias pigGetCursorPos = void function(ImVec2* pOut);
        alias pigGetFrameCount = int function();
        alias pImDrawList_AddNgon = void function(ImDrawList* self, const ImVec2 center, float radius, ImU32 col, int num_segments, float thickness);
        alias pigDebugNodeDrawList = void function(ImGuiWindow* window, const ImDrawList* draw_list, const(char)* label);
        alias pigEnd = void function();
        alias pigTabBarCloseTab = void function(ImGuiTabBar* tab_bar, ImGuiTabItem* tab);
        alias pigIsItemActivated = bool function();
        alias pImGuiInputTextState_ImGuiInputTextState = ImGuiInputTextState* function();
        alias pImRect_GetHeight = float function(ImRect* self);
        alias pImFontAtlas_AddFontDefault = ImFont* function(ImFontAtlas* self, const ImFontConfig* font_cfg);
        alias pImDrawList__OnChangedTextureID = void function(ImDrawList* self);
        alias pigGetColumnsCount = int function();
        alias pigEndChild = void function();
        alias pigNavMoveRequestButNoResultYet = bool function();
        alias pImGuiStyle_ScaleAllSizes = void function(ImGuiStyle* self, float scale_factor);
        alias pigArrowButton = bool function(const(char)* str_id, ImGuiDir dir);
        alias pigSetCursorPosY = void function(float local_y);
        alias pImGuiTextFilter_ImGuiTextFilter = ImGuiTextFilter* function(const(char)* default_filter);
        alias pImGuiStorage_SetFloat = void function(ImGuiStorage* self, ImGuiID key, float val);
        alias pigShadeVertsLinearUV = void function(ImDrawList* draw_list, int vert_start_idx, int vert_end_idx, const ImVec2 a, const ImVec2 b, const ImVec2 uv_a, const ImVec2 uv_b, bool clamp);
        alias pigTableGetColumnIndex = int function();
        alias pigGetTime = double function();
        alias pigBeginPopupContextItem = bool function(const(char)* str_id, ImGuiPopupFlags popup_flags);
        alias pigTableLoadSettings = void function(ImGuiTable* table);
        alias pigSetScrollHereX = void function(float center_x_ratio);
        alias pigSliderScalarN = bool function(const(char)* label, ImGuiDataType data_type, void* p_data, int components, const void* p_min, const void* p_max, const(char)* format, ImGuiSliderFlags flags);
        alias pImDrawList_PathBezierQuadraticCurveTo = void function(ImDrawList* self, const ImVec2 p2, const ImVec2 p3, int num_segments);
        alias pImFontAtlas_GetGlyphRangesChineseSimplifiedCommon = const ImWchar* function(ImFontAtlas* self);
        alias pigGetMousePosOnOpeningCurrentPopup = void function(ImVec2* pOut);
        alias pigVSliderScalar = bool function(const(char)* label, const ImVec2 size, ImGuiDataType data_type, void* p_data, const void* p_min, const void* p_max, const(char)* format, ImGuiSliderFlags flags);
        alias pImFont_RenderChar = void function(ImFont* self, ImDrawList* draw_list, float size, ImVec2 pos, ImU32 col, ImWchar c);
        alias pImFont_RenderText = void function(ImFont* self, ImDrawList* draw_list, float size, ImVec2 pos, ImU32 col, const ImVec4 clip_rect, const(char)* text_begin, const(char)* text_end, float wrap_width, bool cpu_fine_clip);
        alias pigOpenPopupEx = void function(ImGuiID id, ImGuiPopupFlags popup_flags);
        alias pImFontAtlas_SetTexID = void function(ImFontAtlas* self, ImTextureID id);
        alias pigImFontAtlasBuildRender8bppRectFromString = void function(ImFontAtlas* atlas, int x, int y, int w, int h, const(char)* in_str, char in_marker_char, char in_marker_pixel_value);
        alias pImFontAtlas_Clear = void function(ImFontAtlas* self);
        alias pImBitVector_TestBit = bool function(ImBitVector* self, int n);
        alias pImGuiTextFilter_destroy = void function(ImGuiTextFilter* self);
        alias pigBeginPopupModal = bool function(const(char)* name, bool* p_open, ImGuiWindowFlags flags);
        alias pigGetFocusedFocusScope = ImGuiID function();
        alias pigDebugNodeColumns = void function(ImGuiOldColumns* columns);
        alias pigDebugNodeWindow = void function(ImGuiWindow* window, const(char)* label);
        alias pigInputFloat = bool function(const(char)* label, float* v, float step, float step_fast, const(char)* format, ImGuiInputTextFlags flags);
        alias pigDragIntRange2 = bool function(const(char)* label, int* v_current_min, int* v_current_max, float v_speed, int v_min, int v_max, const(char)* format, const(char)* format_max, ImGuiSliderFlags flags);
        alias pImVec2ih_destroy = void function(ImVec2ih* self);
        alias pImDrawList_GetClipRectMax = void function(ImVec2* pOut, ImDrawList* self);
        alias pigInputFloat2 = bool function(const(char)* label, float[2]*/*[2]*/ v, const(char)* format, ImGuiInputTextFlags flags);
        alias pImDrawDataBuilder_ClearFreeMemory = void function(ImDrawDataBuilder* self);
        alias pImGuiWindowSettings_GetName = char* function(ImGuiWindowSettings* self);
        alias pImGuiLastItemDataBackup_Restore = void function(ImGuiLastItemDataBackup* self);
        alias pigImStrdup = char* function(const(char)* str);
        alias pigImFormatStringV = int function(char* buf, size_t buf_size, const(char)* fmt, va_list args);
        alias pigSetTooltipV = void function(const(char)* fmt, va_list args);
        alias pigDataTypeGetInfo = const ImGuiDataTypeInfo* function(ImGuiDataType data_type);
        alias pigVSliderInt = bool function(const(char)* label, const ImVec2 size, int* v, int v_min, int v_max, const(char)* format, ImGuiSliderFlags flags);
        alias pigSetWindowClipRectBeforeSetChannel = void function(ImGuiWindow* window, const ImRect clip_rect);
        alias pImFontGlyphRangesBuilder_ImFontGlyphRangesBuilder = ImFontGlyphRangesBuilder* function();
        alias pigPopTextWrapPos = void function();
        alias pImGuiWindow_TitleBarHeight = float function(ImGuiWindow* self);
        alias pImDrawList_GetClipRectMin = void function(ImVec2* pOut, ImDrawList* self);
        alias pImDrawList_PathStroke = void function(ImDrawList* self, ImU32 col, ImDrawFlags flags, float thickness);
        alias pigBeginTooltip = void function();
        alias pigOpenPopupOnItemClick = void function(const(char)* str_id, ImGuiPopupFlags popup_flags);
        alias pImDrawListSplitter_Merge = void function(ImDrawListSplitter* self, ImDrawList* draw_list);
        alias pImGuiWindow_MenuBarHeight = float function(ImGuiWindow* self);
        alias pImColor_HSV = void function(ImColor* pOut, float h, float s, float v, float a);
        alias pigBeginTableEx = bool function(const(char)* name, ImGuiID id, int columns_count, ImGuiTableFlags flags, const ImVec2 outer_size, float inner_width);
        alias pigSetTabItemClosed = void function(const(char)* tab_or_docked_window_label);
        alias pImFont_AddGlyph = void function(ImFont* self, const ImFontConfig* src_cfg, ImWchar c, float x0, float y0, float x1, float y1, float u0, float v0, float u1, float v1, float advance_x);
        alias pigSetHoveredID = void function(ImGuiID id);
        alias pImFontGlyphRangesBuilder_AddText = void function(ImFontGlyphRangesBuilder* self, const(char)* text, const(char)* text_end);
        alias pImGuiPtrOrIndex_destroy = void function(ImGuiPtrOrIndex* self);
        alias pImGuiInputTextCallbackData_ImGuiInputTextCallbackData = ImGuiInputTextCallbackData* function();
        alias pigImStrdupcpy = char* function(char* dst, size_t* p_dst_size, const(char)* str);
        alias pigColorPicker4 = bool function(const(char)* label, float[4]*/*[4]*/ col, ImGuiColorEditFlags flags, const float* ref_col);
        alias pigColorConvertHSVtoRGB = void function(float h, float s, float v, float* out_r, float* out_g, float* out_b);
        alias pigImBitArrayTestBit = bool function(const ImU32* arr, int n);
        alias pigFindWindowByID = ImGuiWindow* function(ImGuiID id);
        alias pImDrawList_PathBezierCubicCurveTo = void function(ImDrawList* self, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, int num_segments);
        alias pigBeginDragDropTargetCustom = bool function(const ImRect bb, ImGuiID id);
        alias pImGuiContext_destroy = void function(ImGuiContext* self);
        alias pigDragInt3 = bool function(const(char)* label, int[3]*/*[3]*/ v, float v_speed, int v_min, int v_max, const(char)* format, ImGuiSliderFlags flags);
        alias pigImHashStr = ImGuiID function(const(char)* data, size_t data_size, ImU32 seed);
        alias pImDrawList_AddTriangleFilled = void function(ImDrawList* self, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, ImU32 col);
        alias pigTempInputScalar = bool function(const ImRect bb, ImGuiID id, const(char)* label, ImGuiDataType data_type, void* p_data, const(char)* format, const void* p_clamp_min, const void* p_clamp_max);
        alias pigRenderArrow = void function(ImDrawList* draw_list, ImVec2 pos, ImU32 col, ImGuiDir dir, float scale);
        alias pigNewFrame = void function();
        alias pImDrawList_ChannelsSetCurrent = void function(ImDrawList* self, int n);
        alias pImGuiTabItem_ImGuiTabItem = ImGuiTabItem* function();
        alias pImGuiContext_ImGuiContext = ImGuiContext* function(ImFontAtlas* shared_font_atlas);
        alias pigClosePopupToLevel = void function(int remaining, bool restore_focus_to_window_under_popup);
        alias pigSliderFloat2 = bool function(const(char)* label, float[2]*/*[2]*/ v, float v_min, float v_max, const(char)* format, ImGuiSliderFlags flags);
        alias pImGuiPopupData_ImGuiPopupData = ImGuiPopupData* function();
        alias pImDrawList_AddImageQuad = void function(ImDrawList* self, ImTextureID user_texture_id, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, const ImVec2 uv1, const ImVec2 uv2, const ImVec2 uv3, const ImVec2 uv4, ImU32 col);
        alias pigBeginListBox = bool function(const(char)* label, const ImVec2 size);
        alias pImFontAtlas_GetCustomRectByIndex = ImFontAtlasCustomRect* function(ImFontAtlas* self, int index);
        alias pImFontAtlas_GetTexDataAsAlpha8 = void function(ImFontAtlas* self, char** out_pixels, int* out_width, int* out_height, int* out_bytes_per_pixel);
        alias pigGcAwakeTransientWindowBuffers = void function(ImGuiWindow* window);
        alias pImDrawList__OnChangedClipRect = void function(ImDrawList* self);
        alias pigGetColumnsID = ImGuiID function(const(char)* str_id, int count);
        alias pigGetCursorScreenPos = void function(ImVec2* pOut);
        alias pigPushAllowKeyboardFocus = void function(bool allow_keyboard_focus);
        alias pImDrawList_PopTextureID = void function(ImDrawList* self);
        alias pigColumns = void function(int count, const(char)* id, bool border);
        alias pImFontGlyphRangesBuilder_AddChar = void function(ImFontGlyphRangesBuilder* self, ImWchar c);
        alias pigGetColumnIndex = int function();
        alias pigBringWindowToDisplayBack = void function(ImGuiWindow* window);
        alias pImDrawList_PrimVtx = void function(ImDrawList* self, const ImVec2 pos, const ImVec2 uv, ImU32 col);
        alias pImDrawListSplitter_Clear = void function(ImDrawListSplitter* self);
        alias pigTableBeginInitMemory = void function(ImGuiTable* table, int columns_count);
        alias pImDrawList_AddConvexPolyFilled = void function(ImDrawList* self, const ImVec2* points, int num_points, ImU32 col);
        alias pigListBox_Str_arr = bool function(const(char)* label, int* current_item, const(char)** items, int items_count, int height_in_items);
        alias pigListBox_FnBoolPtr = bool function(const(char)* label, int* current_item, bool function(void* data,int idx,const(char)** out_text) items_getter, void* data, int items_count, int height_in_items);
        alias pigPopItemFlag = void function();
        alias pigImBezierCubicClosestPoint = void function(ImVec2* pOut, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, const ImVec2 p, int num_segments);
        alias pigPopColumnsBackground = void function();
        alias pigLogBegin = void function(ImGuiLogType type, int auto_open_depth);
        alias pigTreeNodeV_Str = bool function(const(char)* str_id, const(char)* fmt, va_list args);
        alias pigTreeNodeV_Ptr = bool function(const void* ptr_id, const(char)* fmt, va_list args);
        alias pigRenderTextClippedEx = void function(ImDrawList* draw_list, const ImVec2 pos_min, const ImVec2 pos_max, const(char)* text, const(char)* text_end, const ImVec2* text_size_if_known, const ImVec2 alignment, const ImRect* clip_rect);
        alias pigTableSettingsFindByID = ImGuiTableSettings* function(ImGuiID id);
        alias pImGuiIO_AddInputCharacterUTF16 = void function(ImGuiIO* self, ImWchar16 c);
        alias pImGuiStorage_GetFloatRef = float* function(ImGuiStorage* self, ImGuiID key, float default_val);
        alias pigImStrbolW = const ImWchar* function(const ImWchar* buf_mid_line, const ImWchar* buf_begin);
        alias pImGuiStackSizes_ImGuiStackSizes = ImGuiStackSizes* function();
        alias pigSliderBehavior = bool function(const ImRect bb, ImGuiID id, ImGuiDataType data_type, void* p_v, const void* p_min, const void* p_max, const(char)* format, ImGuiSliderFlags flags, ImRect* out_grab_bb);
        alias pigValue_Bool = void function(const(char)* prefix, bool b);
        alias pigValue_Int = void function(const(char)* prefix, int v);
        alias pigValue_Uint = void function(const(char)* prefix, uint v);
        alias pigValue_Float = void function(const(char)* prefix, float v, const(char)* float_format);
        alias pigBeginTabItem = bool function(const(char)* label, bool* p_open, ImGuiTabItemFlags flags);
        alias pigDebugNodeTable = void function(ImGuiTable* table);
        alias pImGuiViewport_destroy = void function(ImGuiViewport* self);
        alias pigIsNavInputDown = bool function(ImGuiNavInput n);
        alias pImGuiInputTextState_ClearFreeMemory = void function(ImGuiInputTextState* self);
        alias pImGuiViewport_GetWorkCenter = void function(ImVec2* pOut, ImGuiViewport* self);
        alias pigRenderBullet = void function(ImDrawList* draw_list, ImVec2 pos, ImU32 col);
        alias pigDragFloat4 = bool function(const(char)* label, float[4]*/*[4]*/ v, float v_speed, float v_min, float v_max, const(char)* format, ImGuiSliderFlags flags);
        alias pImDrawList__OnChangedVtxOffset = void function(ImDrawList* self);
        alias pigTableSortSpecsSanitize = void function(ImGuiTable* table);
        alias pigFocusTopMostWindowUnderOne = void function(ImGuiWindow* under_this_window, ImGuiWindow* ignore_window);
        alias pigPushID_Str = void function(const(char)* str_id);
        alias pigPushID_StrStr = void function(const(char)* str_id_begin, const(char)* str_id_end);
        alias pigPushID_Ptr = void function(const void* ptr_id);
        alias pigPushID_Int = void function(int int_id);
        alias pigItemHoverable = bool function(const ImRect bb, ImGuiID id);
        alias pImFontAtlas_AddFontFromMemoryTTF = ImFont* function(ImFontAtlas* self, void* font_data, int font_size, float size_pixels, const ImFontConfig* font_cfg, const ImWchar* glyph_ranges);
        alias pigImFontAtlasBuildMultiplyRectAlpha8 = void function(const char[256]*/*[256]*/ table, char* pixels, int x, int y, int w, int h, int stride);
        alias pigTextDisabledV = void function(const(char)* fmt, va_list args);
        alias pigInputScalar = bool function(const(char)* label, ImGuiDataType data_type, void* p_data, const void* p_step, const void* p_step_fast, const(char)* format, ImGuiInputTextFlags flags);
        alias pImGuiPtrOrIndex_ImGuiPtrOrIndex_Ptr = ImGuiPtrOrIndex* function(void* ptr);
        alias pImGuiPtrOrIndex_ImGuiPtrOrIndex_Int = ImGuiPtrOrIndex* function(int index);
        alias pigImLerp_Vec2Float = void function(ImVec2* pOut, const ImVec2 a, const ImVec2 b, float t);
        alias pigImLerp_Vec2Vec2 = void function(ImVec2* pOut, const ImVec2 a, const ImVec2 b, const ImVec2 t);
        alias pigImLerp_Vec4 = void function(ImVec4* pOut, const ImVec4 a, const ImVec4 b, float t);
        alias pigItemSize_Vec2 = void function(const ImVec2 size, float text_baseline_y);
        alias pigItemSize_Rect = void function(const ImRect bb, float text_baseline_y);
        alias pImColor_SetHSV = void function(ImColor* self, float h, float s, float v, float a);
        alias pImFont_IsGlyphRangeUnused = bool function(ImFont* self, uint c_begin, uint c_last);
        alias pigImBezierQuadraticCalc = void function(ImVec2* pOut, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, float t);
        alias pigImParseFormatPrecision = int function(const(char)* format, int default_value);
        alias pigLogToTTY = void function(int auto_open_depth);
        alias pigTableGetColumnWidthAuto = float function(ImGuiTable* table, ImGuiTableColumn* column);
        alias pigButtonBehavior = bool function(const ImRect bb, ImGuiID id, bool* out_hovered, bool* out_held, ImGuiButtonFlags flags);
        alias pImGuiInputTextState_OnKeyPressed = void function(ImGuiInputTextState* self, int key);
        alias pigImLog_Float = float function(float x);
        alias pigImLog_double = double function(double x);
        alias pigSetFocusID = void function(ImGuiID id, ImGuiWindow* window);
        alias pigGetActiveID = ImGuiID function();
        alias pigImLineClosestPoint = void function(ImVec2* pOut, const ImVec2 a, const ImVec2 b, const ImVec2 p);
        alias pigIsItemVisible = bool function();
        alias pigRender = void function();
        alias pigImTriangleArea = float function(const ImVec2 a, const ImVec2 b, const ImVec2 c);
        alias pigBeginChild_Str = bool function(const(char)* str_id, const ImVec2 size, bool border, ImGuiWindowFlags flags);
        alias pigBeginChild_ID = bool function(ImGuiID id, const ImVec2 size, bool border, ImGuiWindowFlags flags);
        alias pigStyleColorsLight = void function(ImGuiStyle* dst);
        alias pigGetScrollX = float function();
        alias pigGetWindowAllowedExtentRect = void function(ImRect* pOut, ImGuiWindow* window);
        alias pigCallContextHooks = void function(ImGuiContext* context, ImGuiContextHookType type);
        alias pImFontAtlas_GetTexDataAsRGBA32 = void function(ImFontAtlas* self, char** out_pixels, int* out_width, int* out_height, int* out_bytes_per_pixel);
        alias pImGuiOnceUponAFrame_ImGuiOnceUponAFrame = ImGuiOnceUponAFrame* function();
        alias pImDrawData_destroy = void function(ImDrawData* self);
        alias pImFont_SetFallbackChar = void function(ImFont* self, ImWchar c);
        alias pigSaveIniSettingsToMemory = const(char)* function(size_t* out_ini_size);
        alias pImGuiNavMoveResult_ImGuiNavMoveResult = ImGuiNavMoveResult* function();
        alias pigTabBarRemoveTab = void function(ImGuiTabBar* tab_bar, ImGuiID tab_id);
        alias pigGetWindowHeight = float function();
        alias pigGetMainViewport = ImGuiViewport* function();
        alias pImGuiTextFilter_PassFilter = bool function(ImGuiTextFilter* self, const(char)* text, const(char)* text_end);
        alias pImFontAtlas_AddFontFromMemoryCompressedBase85TTF = ImFont* function(ImFontAtlas* self, const(char)* compressed_font_data_base85, float size_pixels, const ImFontConfig* font_cfg, const ImWchar* glyph_ranges);
        alias pImFontAtlas_AddFontFromFileTTF = ImFont* function(ImFontAtlas* self, const(char)* filename, float size_pixels, const ImFontConfig* font_cfg, const ImWchar* glyph_ranges);
        alias pigGetCurrentContext = ImGuiContext* function();
        alias pigColorConvertU32ToFloat4 = void function(ImVec4* pOut, ImU32 inItem);
        alias pImDrawList_PathArcToFast = void function(ImDrawList* self, const ImVec2 center, float radius, int a_min_of_12, int a_max_of_12);
        alias pigDragFloat = bool function(const(char)* label, float* v, float v_speed, float v_min, float v_max, const(char)* format, ImGuiSliderFlags flags);
        alias pigGetStyleColorName = const(char)* function(ImGuiCol idx);
        alias pigSetItemDefaultFocus = void function();
        alias pigCalcListClipping = void function(int items_count, float items_height, int* out_items_display_start, int* out_items_display_end);
        alias pigSetNextWindowPos = void function(const ImVec2 pos, ImGuiCond cond, const ImVec2 pivot);
        alias pigDragFloat3 = bool function(const(char)* label, float[3]*/*[3]*/ v, float v_speed, float v_min, float v_max, const(char)* format, ImGuiSliderFlags flags);
        alias pigCaptureKeyboardFromApp = void function(bool want_capture_keyboard_value);
        alias pigGetCurrentTable = ImGuiTable* function();
        alias pImDrawData_Clear = void function(ImDrawData* self);
        alias pImFontAtlas_AddFontFromMemoryCompressedTTF = ImFont* function(ImFontAtlas* self, const void* compressed_font_data, int compressed_font_size, float size_pixels, const ImFontConfig* font_cfg, const ImWchar* glyph_ranges);
        alias pImGuiStoragePair_destroy = void function(ImGuiStoragePair* self);
        alias pigIsItemToggledOpen = bool function();
        alias pigInputInt3 = bool function(const(char)* label, int[3]*/*[3]*/ v, ImGuiInputTextFlags flags);
        alias pigShrinkWidths = void function(ImGuiShrinkWidthItem* items, int count, float width_excess);
        alias pImDrawList_AddText_Vec2 = void function(ImDrawList* self, const ImVec2 pos, ImU32 col, const(char)* text_begin, const(char)* text_end);
        alias pImDrawList_AddText_FontPtr = void function(ImDrawList* self, const ImFont* font, float font_size, const ImVec2 pos, ImU32 col, const(char)* text_begin, const(char)* text_end, float wrap_width, const ImVec4* cpu_fine_clip_rect);
        alias pImDrawList_PrimRectUV = void function(ImDrawList* self, const ImVec2 a, const ImVec2 b, const ImVec2 uv_a, const ImVec2 uv_b, ImU32 col);
        alias pImDrawList_PrimWriteIdx = void function(ImDrawList* self, ImDrawIdx idx);
        alias pImGuiOldColumns_ImGuiOldColumns = ImGuiOldColumns* function();
        alias pigTableRemove = void function(ImGuiTable* table);
        alias pigDebugNodeTableSettings = void function(ImGuiTableSettings* settings);
        alias pImGuiStorage_GetBool = bool function(ImGuiStorage* self, ImGuiID key, bool default_val);
        alias pigRenderFrameBorder = void function(ImVec2 p_min, ImVec2 p_max, float rounding);
        alias pigFindWindowByName = ImGuiWindow* function(const(char)* name);
        alias pigImTextStrToUtf8 = int function(char* buf, int buf_size, const ImWchar* in_text, const ImWchar* in_text_end);
        alias pigTextWrapped = void function(const(char)* fmt, ...);
        alias pigScrollToBringRectIntoView = void function(ImVec2* pOut, ImGuiWindow* window, const ImRect item_rect);
        alias pigInputInt = bool function(const(char)* label, int* v, int step, int step_fast, ImGuiInputTextFlags flags);
        alias pImVec2_ImVec2_Nil = ImVec2* function();
        alias pImVec2_ImVec2_Float = ImVec2* function(float _x, float _y);
        alias pImGuiTextBuffer_size = int function(ImGuiTextBuffer* self);
        alias pImFontAtlas_GetGlyphRangesDefault = const ImWchar* function(ImFontAtlas* self);
        alias pImFontAtlas_ClearTexData = void function(ImFontAtlas* self);
        alias pImFont_GetCharAdvance = float function(ImFont* self, ImWchar c);
        alias pigSliderFloat3 = bool function(const(char)* label, float[3]*/*[3]*/ v, float v_min, float v_max, const(char)* format, ImGuiSliderFlags flags);
        alias pImDrawList_PathFillConvex = void function(ImDrawList* self, ImU32 col);
        alias pImGuiTextBuffer_ImGuiTextBuffer = ImGuiTextBuffer* function();
        alias pImGuiTabItem_destroy = void function(ImGuiTabItem* self);
        alias pigSliderAngle = bool function(const(char)* label, float* v_rad, float v_degrees_min, float v_degrees_max, const(char)* format, ImGuiSliderFlags flags);
        alias pImGuiTableColumnSortSpecs_destroy = void function(ImGuiTableColumnSortSpecs* self);
        alias pigSetWindowPos_Vec2 = void function(const ImVec2 pos, ImGuiCond cond);
        alias pigSetWindowPos_Str = void function(const(char)* name, const ImVec2 pos, ImGuiCond cond);
        alias pigSetWindowPos_WindowPtr = void function(ImGuiWindow* window, const ImVec2 pos, ImGuiCond cond);
        alias pigTempInputText = bool function(const ImRect bb, ImGuiID id, const(char)* label, char* buf, int buf_size, ImGuiInputTextFlags flags);
        alias pigSetScrollHereY = void function(float center_y_ratio);
        alias pImGuiViewport_ImGuiViewport = ImGuiViewport* function();
        alias pigProgressBar = void function(float fraction, const ImVec2 size_arg, const(char)* overlay);
        alias pImDrawList_CloneOutput = ImDrawList* function(ImDrawList* self);
        alias pImFontGlyphRangesBuilder_destroy = void function(ImFontGlyphRangesBuilder* self);
        alias pImVec1_destroy = void function(ImVec1* self);
        alias pigPushColumnClipRect = void function(int column_index);
        alias pigLogTextV = void function(const(char)* fmt, va_list args);
        alias pigImTextCharFromUtf8 = int function(uint* out_char, const(char)* in_text, const(char)* in_text_end);
        alias pImRect_ImRect_Nil = ImRect* function();
        alias pImRect_ImRect_Vec2 = ImRect* function(const ImVec2 min, const ImVec2 max);
        alias pImRect_ImRect_Vec4 = ImRect* function(const ImVec4 v);
        alias pImRect_ImRect_Float = ImRect* function(float x1, float y1, float x2, float y2);
        alias pigGetTopMostPopupModal = ImGuiWindow* function();
        alias pImDrawListSplitter_Split = void function(ImDrawListSplitter* self, ImDrawList* draw_list, int count);
        alias pigBulletText = void function(const(char)* fmt, ...);
        alias pigImFontAtlasBuildFinish = void function(ImFontAtlas* atlas);
        alias pigDebugNodeViewport = void function(ImGuiViewportP* viewport);
        alias pImDrawList_AddQuad = void function(ImDrawList* self, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, ImU32 col, float thickness);
        alias pigIsItemDeactivated = bool function();
        alias pigGetColorU32_Col = ImU32 function(ImGuiCol idx, float alpha_mul);
        alias pigGetColorU32_Vec4 = ImU32 function(const ImVec4 col);
        alias pigGetColorU32_U32 = ImU32 function(ImU32 col);
        alias pImGuiWindow_GetIDFromRectangle = ImGuiID function(ImGuiWindow* self, const ImRect r_abs);
        alias pImDrawList_AddDrawCmd = void function(ImDrawList* self);
        alias pigUpdateWindowParentAndRootLinks = void function(ImGuiWindow* window, ImGuiWindowFlags flags, ImGuiWindow* parent_window);
        alias pigSetCursorPosX = void function(float local_x);
        alias pigInputFloat4 = bool function(const(char)* label, float[4]*/*[4]*/ v, const(char)* format, ImGuiInputTextFlags flags);
        alias pigSeparator = void function();
        alias pImRect_Translate = void function(ImRect* self, const ImVec2 d);
        alias pImDrawList_PrimUnreserve = void function(ImDrawList* self, int idx_count, int vtx_count);
        alias pigColorPickerOptionsPopup = void function(const float* ref_col, ImGuiColorEditFlags flags);
        alias pImRect_IsInverted = bool function(ImRect* self);
        alias pigGetKeyIndex = int function(ImGuiKey imgui_key);
        alias pImGuiMetricsConfig_destroy = void function(ImGuiMetricsConfig* self);
        alias pigPushItemFlag = void function(ImGuiItemFlags option, bool enabled);
        alias pigScrollbar = void function(ImGuiAxis axis);
        alias pigDebugNodeWindowsList = void function(ImVector!(ImGuiWindow*)* windows, const(char)* label);
        alias pImDrawList_PrimWriteVtx = void function(ImDrawList* self, const ImVec2 pos, const ImVec2 uv, ImU32 col);
        alias pigSetActiveID = void function(ImGuiID id, ImGuiWindow* window);
        alias pImGuiPayload_IsDataType = bool function(ImGuiPayload* self, const(char)* type);
        alias pigSetWindowSize_Vec2 = void function(const ImVec2 size, ImGuiCond cond);
        alias pigSetWindowSize_Str = void function(const(char)* name, const ImVec2 size, ImGuiCond cond);
        alias pigSetWindowSize_WindowPtr = void function(ImGuiWindow* window, const ImVec2 size, ImGuiCond cond);
        alias pImFontGlyphRangesBuilder_BuildRanges = void function(ImFontGlyphRangesBuilder* self, ImVector!(ImWchar)* out_ranges);
        alias pigTreePop = void function();
        alias pigTableGetCellBgRect = void function(ImRect* pOut, const ImGuiTable* table, int column_n);
        alias pImFont_AddRemapChar = void function(ImFont* self, ImWchar dst, ImWchar src, bool overwrite_dst);
        alias pigNavMoveRequestCancel = void function();
        alias pigText = void function(const(char)* fmt, ...);
        alias pigCollapseButton = bool function(ImGuiID id, const ImVec2 pos);
        alias pImGuiWindow_TitleBarRect = void function(ImRect* pOut, ImGuiWindow* self);
        alias pigIsItemFocused = bool function();
        alias pigMemAlloc = void* function(size_t size);
        alias pImGuiStackSizes_destroy = void function(ImGuiStackSizes* self);
        alias pigColorPicker3 = bool function(const(char)* label, float[3]*/*[3]*/ col, ImGuiColorEditFlags flags);
        alias pImGuiTextBuffer_destroy = void function(ImGuiTextBuffer* self);
        alias pigGetColumnOffset = float function(int column_index);
        alias pImRect_GetSize = void function(ImVec2* pOut, ImRect* self);
        alias pigSetItemUsingMouseWheel = void function();
        alias pigIsWindowCollapsed = bool function();
        alias pImGuiNextItemData_ClearFlags = void function(ImGuiNextItemData* self);
        alias pigBeginCombo = bool function(const(char)* label, const(char)* preview_value, ImGuiComboFlags flags);
        alias pImRect_Expand_Float = void function(ImRect* self, const float amount);
        alias pImRect_Expand_Vec2 = void function(ImRect* self, const ImVec2 amount);
        alias pigOpenPopup = void function(const(char)* str_id, ImGuiPopupFlags popup_flags);
        alias pigImCharIsBlankW = bool function(uint c);
        alias pImFont_SetGlyphVisible = void function(ImFont* self, ImWchar c, bool visible);
        alias pigFindOrCreateWindowSettings = ImGuiWindowSettings* function(const(char)* name);
        alias pigInputScalarN = bool function(const(char)* label, ImGuiDataType data_type, void* p_data, int components, const void* p_step, const void* p_step_fast, const(char)* format, ImGuiInputTextFlags flags);
        alias pImDrawList_PrimQuadUV = void function(ImDrawList* self, const ImVec2 a, const ImVec2 b, const ImVec2 c, const ImVec2 d, const ImVec2 uv_a, const ImVec2 uv_b, const ImVec2 uv_c, const ImVec2 uv_d, ImU32 col);
        alias pigPopID = void function();
        alias pigEndTabBar = void function();
        alias pigPopAllowKeyboardFocus = void function();
        alias pImDrawList_AddImage = void function(ImDrawList* self, ImTextureID user_texture_id, const ImVec2 p_min, const ImVec2 p_max, const ImVec2 uv_min, const ImVec2 uv_max, ImU32 col);
        alias pigBeginTabBar = bool function(const(char)* str_id, ImGuiTabBarFlags flags);
        alias pigGetCursorPosY = float function();
        alias pigCalcTextSize = void function(ImVec2* pOut, const(char)* text, const(char)* text_end, bool hide_text_after_double_hash, float wrap_width);
        alias pImFont_CalcTextSizeA = void function(ImVec2* pOut, ImFont* self, float size, float max_width, float wrap_width, const(char)* text_begin, const(char)* text_end, const char** remaining);
        alias pigImClamp = void function(ImVec2* pOut, const ImVec2 v, const ImVec2 mn, ImVec2 mx);
        alias pigGetColumnWidth = float function(int column_index);
        alias pigTableHeader = void function(const(char)* label);
        alias pImGuiPayload_Clear = void function(ImGuiPayload* self);
        alias pImGuiTextBuffer_reserve = void function(ImGuiTextBuffer* self, int capacity);
        alias pImGuiInputTextState_CursorAnimReset = void function(ImGuiInputTextState* self);
        alias pImRect_ClipWithFull = void function(ImRect* self, const ImRect r);
        alias pigGetFontTexUvWhitePixel = void function(ImVec2* pOut);
        alias pImDrawList_ChannelsSplit = void function(ImDrawList* self, int count);
        alias pigCalcWindowNextAutoFitSize = void function(ImVec2* pOut, ImGuiWindow* window);
        alias pigPopFont = void function();
        alias pigImTriangleContainsPoint = bool function(const ImVec2 a, const ImVec2 b, const ImVec2 c, const ImVec2 p);
        alias pigRenderRectFilledWithHole = void function(ImDrawList* draw_list, ImRect outer, ImRect inner, ImU32 col, float rounding);
        alias pigImFloor_Float = float function(float f);
        alias pigImFloor_Vec2 = void function(ImVec2* pOut, const ImVec2 v);
        alias pImDrawList_AddRect = void function(ImDrawList* self, const ImVec2 p_min, const ImVec2 p_max, ImU32 col, float rounding, ImDrawFlags flags, float thickness);
        alias pigImParseFormatFindEnd = const(char)* function(const(char)* format);
        alias pImGuiTableColumnSettings_destroy = void function(ImGuiTableColumnSettings* self);
        alias pImGuiInputTextCallbackData_ClearSelection = void function(ImGuiInputTextCallbackData* self);
        alias pigErrorCheckEndFrameRecover = void function(ImGuiErrorLogCallback log_callback, void* user_data);
        alias pImGuiTextRange_split = void function(ImGuiTextRange* self, char separator, ImVector!(ImGuiTextRange)* outItem);
        alias pImBitVector_Clear = void function(ImBitVector* self);
        alias pigCreateNewWindowSettings = ImGuiWindowSettings* function(const(char)* name);
        alias pigGetDrawListSharedData = ImDrawListSharedData* function();
        alias pigImFileClose = bool function(ImFileHandle file);
        alias pigBeginChildEx = bool function(const(char)* name, ImGuiID id, const ImVec2 size_arg, bool border, ImGuiWindowFlags flags);
        alias pImGuiNextWindowData_ClearFlags = void function(ImGuiNextWindowData* self);
        alias pImFontGlyphRangesBuilder_GetBit = bool function(ImFontGlyphRangesBuilder* self, size_t n);
        alias pigImRotate = void function(ImVec2* pOut, const ImVec2 v, float cos_a, float sin_a);
        alias pigImGetDirQuadrantFromDelta = ImGuiDir function(float dx, float dy);
        alias pigTableMergeDrawChannels = void function(ImGuiTable* table);
        alias pImFontAtlas_AddFont = ImFont* function(ImFontAtlas* self, const ImFontConfig* font_cfg);
        alias pigGetNavInputAmount2d = void function(ImVec2* pOut, ImGuiNavDirSourceFlags dir_sources, ImGuiInputReadMode mode, float slow_factor, float fast_factor);
        __gshared {
            pImDrawList_AddCircleFilled ImDrawList_AddCircleFilled;
            pigEndTable igEndTable;
            pigGetForegroundDrawList_Nil igGetForegroundDrawList_Nil;
            pigGetForegroundDrawList_WindowPtr igGetForegroundDrawList_WindowPtr;
            pigGetForegroundDrawList_ViewportPtr igGetForegroundDrawList_ViewportPtr;
            pImFontAtlas_GetGlyphRangesChineseFull ImFontAtlas_GetGlyphRangesChineseFull;
            pigBringWindowToDisplayFront igBringWindowToDisplayFront;
            pigInitialize igInitialize;
            pImFontAtlas_AddCustomRectRegular ImFontAtlas_AddCustomRectRegular;
            pigIsMouseDragPastThreshold igIsMouseDragPastThreshold;
            pigSetWindowFontScale igSetWindowFontScale;
            pigSliderFloat igSliderFloat;
            pigImMax igImMax;
            pImRect_GetTR ImRect_GetTR;
            pigTableSetupColumn igTableSetupColumn;
            pImFontAtlas_GetGlyphRangesThai ImFontAtlas_GetGlyphRangesThai;
            pImGuiInputTextState_ClearSelection ImGuiInputTextState_ClearSelection;
            pImFont_GrowIndex ImFont_GrowIndex;
            pigClosePopupsOverWindow igClosePopupsOverWindow;
            pImFontAtlas_ClearInputData ImFontAtlas_ClearInputData;
            pImGuiWindowSettings_destroy ImGuiWindowSettings_destroy;
            pigIsMouseDragging igIsMouseDragging;
            pigLoadIniSettingsFromDisk igLoadIniSettingsFromDisk;
            pigImBezierCubicCalc igImBezierCubicCalc;
            pImGuiTextBuffer_end ImGuiTextBuffer_end;
            pImGuiTabBar_destroy ImGuiTabBar_destroy;
            pigSetClipboardText igSetClipboardText;
            pigRenderColorRectWithAlphaCheckerboard igRenderColorRectWithAlphaCheckerboard;
            pigFindBestWindowPosForPopup igFindBestWindowPosForPopup;
            pigRadioButton_Bool igRadioButton_Bool;
            pigRadioButton_IntPtr igRadioButton_IntPtr;
            pImGuiTextFilter_Clear ImGuiTextFilter_Clear;
            pImRect_TranslateX ImRect_TranslateX;
            pigGetWindowPos igGetWindowPos;
            pImGuiIO_ClearInputCharacters ImGuiIO_ClearInputCharacters;
            pigImBitArraySetBit igImBitArraySetBit;
            pImDrawDataBuilder_FlattenIntoSingleLayer ImDrawDataBuilder_FlattenIntoSingleLayer;
            pigRenderTextWrapped igRenderTextWrapped;
            pigSpacing igSpacing;
            pImRect_TranslateY ImRect_TranslateY;
            pImGuiTextBuffer_c_str ImGuiTextBuffer_c_str;
            pigTabBarFindTabByID igTabBarFindTabByID;
            pigDataTypeApplyOpFromText igDataTypeApplyOpFromText;
            pImGuiInputTextState_destroy ImGuiInputTextState_destroy;
            pigGetDrawData igGetDrawData;
            pigRenderRectFilledRangeH igRenderRectFilledRangeH;
            pigPopItemWidth igPopItemWidth;
            pigIsWindowAppearing igIsWindowAppearing;
            pigGetAllocatorFunctions igGetAllocatorFunctions;
            pigImFontAtlasGetBuilderForStbTruetype igImFontAtlasGetBuilderForStbTruetype;
            pigFindOrCreateColumns igFindOrCreateColumns;
            pImGuiStorage_GetVoidPtr ImGuiStorage_GetVoidPtr;
            pImGuiInputTextState_GetRedoAvailCount ImGuiInputTextState_GetRedoAvailCount;
            pigIsPopupOpen_Str igIsPopupOpen_Str;
            pigIsPopupOpen_ID igIsPopupOpen_ID;
            pigTableGetSortSpecs igTableGetSortSpecs;
            pigTableDrawBorders igTableDrawBorders;
            pImGuiTable_ImGuiTable ImGuiTable_ImGuiTable;
            pigInputDouble igInputDouble;
            pigUnindent igUnindent;
            pigIsDragDropPayloadBeingAccepted igIsDragDropPayloadBeingAccepted;
            pigGetFontSize igGetFontSize;
            pImGuiMenuColumns_DeclColumns ImGuiMenuColumns_DeclColumns;
            pImFontAtlas_CalcCustomRectUV ImFontAtlas_CalcCustomRectUV;
            pigGetFrameHeightWithSpacing igGetFrameHeightWithSpacing;
            pImDrawListSplitter_destroy ImDrawListSplitter_destroy;
            pigGetItemRectMax igGetItemRectMax;
            pigFocusableItemRegister igFocusableItemRegister;
            pigDragInt igDragInt;
            pigGetFont igGetFont;
            pigDragFloatRange2 igDragFloatRange2;
            pigTableUpdateLayout igTableUpdateLayout;
            pigImStreolRange igImStreolRange;
            pImGuiStorage_Clear ImGuiStorage_Clear;
            pImGuiViewportP_UpdateWorkRect ImGuiViewportP_UpdateWorkRect;
            pigTableNextColumn igTableNextColumn;
            pImGuiWindow_GetID_Str ImGuiWindow_GetID_Str;
            pImGuiWindow_GetID_Ptr ImGuiWindow_GetID_Ptr;
            pImGuiWindow_GetID_Int ImGuiWindow_GetID_Int;
            pigImFontAtlasBuildPackCustomRects igImFontAtlasBuildPackCustomRects;
            pigTableGetColumnFlags igTableGetColumnFlags;
            pigIsActiveIdUsingKey igIsActiveIdUsingKey;
            pigSetCursorScreenPos igSetCursorScreenPos;
            pigImStristr igImStristr;
            pImFont_GetDebugName ImFont_GetDebugName;
            pigBeginPopupContextWindow igBeginPopupContextWindow;
            pigBeginTable igBeginTable;
            pigButtonEx igButtonEx;
            pigTextEx igTextEx;
            pImGuiPayload_IsPreview ImGuiPayload_IsPreview;
            pigLabelTextV igLabelTextV;
            pigImStrSkipBlank igImStrSkipBlank;
            pigPushColumnsBackground igPushColumnsBackground;
            pImGuiWindow_ImGuiWindow ImGuiWindow_ImGuiWindow;
            pigGetScrollMaxX igGetScrollMaxX;
            pImBitVector_Create ImBitVector_Create;
            pigCloseCurrentPopup igCloseCurrentPopup;
            pigImBitArraySetBitRange igImBitArraySetBitRange;
            pigSplitterBehavior igSplitterBehavior;
            pImGuiTableSortSpecs_ImGuiTableSortSpecs ImGuiTableSortSpecs_ImGuiTableSortSpecs;
            pigGetMouseDragDelta igGetMouseDragDelta;
            pigSetWindowCollapsed_Bool igSetWindowCollapsed_Bool;
            pigSetWindowCollapsed_Str igSetWindowCollapsed_Str;
            pigSetWindowCollapsed_WindowPtr igSetWindowCollapsed_WindowPtr;
            pigTableDrawContextMenu igTableDrawContextMenu;
            pigTextDisabled igTextDisabled;
            pigDebugNodeStorage igDebugNodeStorage;
            pigFindBestWindowPosForPopupEx igFindBestWindowPosForPopupEx;
            pigTableSetColumnEnabled igTableSetColumnEnabled;
            pigShowUserGuide igShowUserGuide;
            pigEndPopup igEndPopup;
            pigClearActiveID igClearActiveID;
            pigBeginChildFrame igBeginChildFrame;
            pImGuiSettingsHandler_destroy ImGuiSettingsHandler_destroy;
            pImDrawList__ResetForNewFrame ImDrawList__ResetForNewFrame;
            pImGuiTextBuffer_append ImGuiTextBuffer_append;
            pImGuiInputTextState_GetUndoAvailCount ImGuiInputTextState_GetUndoAvailCount;
            pigEndFrame igEndFrame;
            pImGuiTableColumn_destroy ImGuiTableColumn_destroy;
            pImGuiTextRange_empty ImGuiTextRange_empty;
            pImGuiInputTextState_ClearText ImGuiInputTextState_ClearText;
            pigIsRectVisible_Nil igIsRectVisible_Nil;
            pigIsRectVisible_Vec2 igIsRectVisible_Vec2;
            pImGuiInputTextCallbackData_HasSelection ImGuiInputTextCallbackData_HasSelection;
            pigCalcWrapWidthForPos igCalcWrapWidthForPos;
            pigGetIDWithSeed igGetIDWithSeed;
            pigImUpperPowerOfTwo igImUpperPowerOfTwo;
            pigIsMouseClicked igIsMouseClicked;
            pigColorConvertRGBtoHSV igColorConvertRGBtoHSV;
            pigPushFocusScope igPushFocusScope;
            pigSetNextWindowFocus igSetNextWindowFocus;
            pigGetDefaultFont igGetDefaultFont;
            pigGetClipboardText igGetClipboardText;
            pigIsAnyItemHovered igIsAnyItemHovered;
            pigTableResetSettings igTableResetSettings;
            pImGuiListClipper_ImGuiListClipper ImGuiListClipper_ImGuiListClipper;
            pigTableGetHoveredColumn igTableGetHoveredColumn;
            pigImStrlenW igImStrlenW;
            pigBeginPopup igBeginPopup;
            pigTableGetRowIndex igTableGetRowIndex;
            pigImFileGetSize igImFileGetSize;
            pImGuiSettingsHandler_ImGuiSettingsHandler ImGuiSettingsHandler_ImGuiSettingsHandler;
            pigMenuItem_Bool igMenuItem_Bool;
            pigMenuItem_BoolPtr igMenuItem_BoolPtr;
            pigImStrTrimBlanks igImStrTrimBlanks;
            pImGuiStyleMod_ImGuiStyleMod_Int ImGuiStyleMod_ImGuiStyleMod_Int;
            pImGuiStyleMod_ImGuiStyleMod_Float ImGuiStyleMod_ImGuiStyleMod_Float;
            pImGuiStyleMod_ImGuiStyleMod_Vec2 ImGuiStyleMod_ImGuiStyleMod_Vec2;
            pImFontConfig_destroy ImFontConfig_destroy;
            pigBeginPopupEx igBeginPopupEx;
            pigImCharIsBlankA igImCharIsBlankA;
            pigResetMouseDragDelta igResetMouseDragDelta;
            pImGuiListClipper_End ImGuiListClipper_End;
            pigSaveIniSettingsToDisk igSaveIniSettingsToDisk;
            pigDestroyContext igDestroyContext;
            pigSetNextWindowContentSize igSetNextWindowContentSize;
            pigGetWindowScrollbarRect igGetWindowScrollbarRect;
            pigTableSetupScrollFreeze igTableSetupScrollFreeze;
            pImGuiTableSettings_GetColumnSettings ImGuiTableSettings_GetColumnSettings;
            pigInputTextMultiline igInputTextMultiline;
            pigIsClippedEx igIsClippedEx;
            pigGetWindowScrollbarID igGetWindowScrollbarID;
            pImGuiTextFilter_IsActive ImGuiTextFilter_IsActive;
            pImDrawListSharedData_ImDrawListSharedData ImDrawListSharedData_ImDrawListSharedData;
            pImFontAtlas_GetMouseCursorTexData ImFontAtlas_GetMouseCursorTexData;
            pigLogText igLogText;
            pImGuiTableColumnSettings_ImGuiTableColumnSettings ImGuiTableColumnSettings_ImGuiTableColumnSettings;
            pigImStrnicmp igImStrnicmp;
            pigColorEditOptionsPopup igColorEditOptionsPopup;
            pigGetTextLineHeightWithSpacing igGetTextLineHeightWithSpacing;
            pigTableFixColumnSortDirection igTableFixColumnSortDirection;
            pigPushStyleVar_Float igPushStyleVar_Float;
            pigPushStyleVar_Vec2 igPushStyleVar_Vec2;
            pigIsActiveIdUsingNavInput igIsActiveIdUsingNavInput;
            pigGetInputTextState igGetInputTextState;
            pigFindRenderedTextEnd igFindRenderedTextEnd;
            pImFontAtlas_ClearFonts ImFontAtlas_ClearFonts;
            pigTextColoredV igTextColoredV;
            pigIsKeyReleased igIsKeyReleased;
            pigTabItemLabelAndCloseButton igTabItemLabelAndCloseButton;
            pImGuiTableColumnSortSpecs_ImGuiTableColumnSortSpecs ImGuiTableColumnSortSpecs_ImGuiTableColumnSortSpecs;
            pigLogToClipboard igLogToClipboard;
            pImFontAtlas_GetGlyphRangesKorean ImFontAtlas_GetGlyphRangesKorean;
            pImFontGlyphRangesBuilder_SetBit ImFontGlyphRangesBuilder_SetBit;
            pigLogSetNextTextDecoration igLogSetNextTextDecoration;
            pigStyleColorsClassic igStyleColorsClassic;
            pImGuiTabBar_GetTabOrder ImGuiTabBar_GetTabOrder;
            pigBegin igBegin;
            pImGuiLastItemDataBackup_ImGuiLastItemDataBackup ImGuiLastItemDataBackup_ImGuiLastItemDataBackup;
            pigBeginMenuBar igBeginMenuBar;
            pigDataTypeClamp igDataTypeClamp;
            pigButton igButton;
            pImFontGlyphRangesBuilder_Clear ImFontGlyphRangesBuilder_Clear;
            pImGuiMenuColumns_destroy ImGuiMenuColumns_destroy;
            pigImStrncpy igImStrncpy;
            pImGuiNextWindowData_ImGuiNextWindowData ImGuiNextWindowData_ImGuiNextWindowData;
            pigImBezierCubicClosestPointCasteljau igImBezierCubicClosestPointCasteljau;
            pigItemAdd igItemAdd;
            pigIsWindowNavFocusable igIsWindowNavFocusable;
            pigGetScrollY igGetScrollY;
            pImGuiOldColumnData_ImGuiOldColumnData ImGuiOldColumnData_ImGuiOldColumnData;
            pImRect_GetWidth ImRect_GetWidth;
            pigEndListBox igEndListBox;
            pigGetItemStatusFlags igGetItemStatusFlags;
            pigPopFocusScope igPopFocusScope;
            pigGetStyleColorVec4 igGetStyleColorVec4;
            pigTableFindByID igTableFindByID;
            pigShutdown igShutdown;
            pigRenderText igRenderText;
            pigTablePushBackgroundChannel igTablePushBackgroundChannel;
            pImRect_ClipWith ImRect_ClipWith;
            pImRect_GetTL ImRect_GetTL;
            pImDrawListSplitter_ImDrawListSplitter ImDrawListSplitter_ImDrawListSplitter;
            pImDrawList__CalcCircleAutoSegmentCount ImDrawList__CalcCircleAutoSegmentCount;
            pigSetWindowFocus_Nil igSetWindowFocus_Nil;
            pigSetWindowFocus_Str igSetWindowFocus_Str;
            pigInvisibleButton igInvisibleButton;
            pigTableSetColumnIndex igTableSetColumnIndex;
            pigRenderMouseCursor igRenderMouseCursor;
            pigImFontAtlasBuildInit igImFontAtlasBuildInit;
            pigTextColored igTextColored;
            pigSliderScalar igSliderScalar;
            pImDrawListSplitter_ClearFreeMemory ImDrawListSplitter_ClearFreeMemory;
            pImGuiStyle_ImGuiStyle ImGuiStyle_ImGuiStyle;
            pImGuiOldColumnData_destroy ImGuiOldColumnData_destroy;
            pImFontConfig_ImFontConfig ImFontConfig_ImFontConfig;
            pigIsMouseDown igIsMouseDown;
            pImGuiTabBar_GetTabName ImGuiTabBar_GetTabName;
            pigDebugNodeTabBar igDebugNodeTabBar;
            pigNewLine igNewLine;
            pigMemFree igMemFree;
            pigCalcTypematicRepeatAmount igCalcTypematicRepeatAmount;
            pigNextColumn igNextColumn;
            pigRenderFrame igRenderFrame;
            pigLogButtons igLogButtons;
            pigEndTabItem igEndTabItem;
            pImFont_ClearOutputData ImFont_ClearOutputData;
            pImFont_ImFont ImFont_ImFont;
            pigRenderArrowPointingAt igRenderArrowPointingAt;
            pigVSliderFloat igVSliderFloat;
            pigTableUpdateBorders igTableUpdateBorders;
            pigEndGroup igEndGroup;
            pigPlotLines_FloatPtr igPlotLines_FloatPtr;
            pigPlotLines_FnFloatPtr igPlotLines_FnFloatPtr;
            pigGetColumnNormFromOffset igGetColumnNormFromOffset;
            pigSetCurrentFont igSetCurrentFont;
            pigSetItemAllowOverlap igSetItemAllowOverlap;
            pImGuiStorage_GetVoidPtrRef ImGuiStorage_GetVoidPtrRef;
            pigCheckboxFlags_IntPtr igCheckboxFlags_IntPtr;
            pigCheckboxFlags_UintPtr igCheckboxFlags_UintPtr;
            pigCheckboxFlags_S64Ptr igCheckboxFlags_S64Ptr;
            pigCheckboxFlags_U64Ptr igCheckboxFlags_U64Ptr;
            pImGuiNavMoveResult_Clear ImGuiNavMoveResult_Clear;
            pImRect_destroy ImRect_destroy;
            pigImTriangleBarycentricCoords igImTriangleBarycentricCoords;
            pigTreeNodeBehavior igTreeNodeBehavior;
            pImFontGlyphRangesBuilder_AddRanges ImFontGlyphRangesBuilder_AddRanges;
            pigTableSetBgColor igTableSetBgColor;
            pImFontAtlas_GetGlyphRangesVietnamese ImFontAtlas_GetGlyphRangesVietnamese;
            pImGuiContextHook_ImGuiContextHook ImGuiContextHook_ImGuiContextHook;
            pigGetVersion igGetVersion;
            pImDrawList_ImDrawList ImDrawList_ImDrawList;
            pigRenderTextEllipsis igRenderTextEllipsis;
            pImGuiListClipper_destroy ImGuiListClipper_destroy;
            pImGuiTableSortSpecs_destroy ImGuiTableSortSpecs_destroy;
            pigPushOverrideID igPushOverrideID;
            pigImMul igImMul;
            pigSetScrollY_Float igSetScrollY_Float;
            pigSetScrollY_WindowPtr igSetScrollY_WindowPtr;
            pImFont_CalcWordWrapPositionA ImFont_CalcWordWrapPositionA;
            pigSmallButton igSmallButton;
            pImGuiTableColumn_ImGuiTableColumn ImGuiTableColumn_ImGuiTableColumn;
            pImGuiWindow_destroy ImGuiWindow_destroy;
            pigTableGetColumnResizeID igTableGetColumnResizeID;
            pigCombo_Str_arr igCombo_Str_arr;
            pigCombo_Str igCombo_Str;
            pigCombo_FnBoolPtr igCombo_FnBoolPtr;
            pigIsWindowChildOf igIsWindowChildOf;
            pImGuiWindow_CalcFontSize ImGuiWindow_CalcFontSize;
            pigTableSetColumnWidth igTableSetColumnWidth;
            pImDrawList_AddLine ImDrawList_AddLine;
            pImDrawList_AddCircle ImDrawList_AddCircle;
            pImGuiInputTextState_SelectAll ImGuiInputTextState_SelectAll;
            pigImParseFormatTrimDecorations igImParseFormatTrimDecorations;
            pImGuiMetricsConfig_ImGuiMetricsConfig ImGuiMetricsConfig_ImGuiMetricsConfig;
            pImGuiTabBar_ImGuiTabBar ImGuiTabBar_ImGuiTabBar;
            pImGuiViewport_GetCenter ImGuiViewport_GetCenter;
            pigDebugDrawItemRect igDebugDrawItemRect;
            pigTreeNodeBehaviorIsOpen igTreeNodeBehaviorIsOpen;
            pigImTextCountUtf8BytesFromChar igImTextCountUtf8BytesFromChar;
            pigSetMouseCursor igSetMouseCursor;
            pigBeginColumns igBeginColumns;
            pigGetIO igGetIO;
            pigDragBehavior igDragBehavior;
            pigImModPositive igImModPositive;
            pImFontAtlasCustomRect_destroy ImFontAtlasCustomRect_destroy;
            pImGuiPayload_destroy ImGuiPayload_destroy;
            pigEndMenu igEndMenu;
            pigImSaturate igImSaturate;
            pImDrawList_PrimRect ImDrawList_PrimRect;
            pigImLinearSweep igImLinearSweep;
            pigUpdateMouseMovingWindowNewFrame igUpdateMouseMovingWindowNewFrame;
            pImDrawList_AddRectFilled ImDrawList_AddRectFilled;
            pImGuiPopupData_destroy ImGuiPopupData_destroy;
            pigFindSettingsHandler igFindSettingsHandler;
            pigDragInt2 igDragInt2;
            pigSetColorEditOptions igSetColorEditOptions;
            pigIsAnyMouseDown igIsAnyMouseDown;
            pImGuiTextFilter_Build ImGuiTextFilter_Build;
            pigTabItemCalcSize igTabItemCalcSize;
            pigSetNextWindowCollapsed igSetNextWindowCollapsed;
            pigSetLastItemData igSetLastItemData;
            pigLogToBuffer igLogToBuffer;
            pigImFileLoadToMemory igImFileLoadToMemory;
            pImFontAtlas_GetGlyphRangesCyrillic ImFontAtlas_GetGlyphRangesCyrillic;
            pImGuiStyle_destroy ImGuiStyle_destroy;
            pImDrawList_destroy ImDrawList_destroy;
            pImVec4_destroy ImVec4_destroy;
            pigRenderCheckMark igRenderCheckMark;
            pigTreeNodeEx_Str igTreeNodeEx_Str;
            pigTreeNodeEx_StrStr igTreeNodeEx_StrStr;
            pigTreeNodeEx_Ptr igTreeNodeEx_Ptr;
            pImBitVector_SetBit ImBitVector_SetBit;
            pigSetColumnWidth igSetColumnWidth;
            pImGuiNavMoveResult_destroy ImGuiNavMoveResult_destroy;
            pigIsItemClicked igIsItemClicked;
            pigTableOpenContextMenu igTableOpenContextMenu;
            pImDrawList_AddCallback ImDrawList_AddCallback;
            pigGetMousePos igGetMousePos;
            pigDataTypeCompare igDataTypeCompare;
            pigImageButtonEx igImageButtonEx;
            pImDrawListSharedData_SetCircleTessellationMaxError ImDrawListSharedData_SetCircleTessellationMaxError;
            pigGetWindowResizeID igGetWindowResizeID;
            pigBullet igBullet;
            pigTableSaveSettings igTableSaveSettings;
            pigTableGetBoundSettings igTableGetBoundSettings;
            pigGetHoveredID igGetHoveredID;
            pigGetWindowContentRegionMin igGetWindowContentRegionMin;
            pigTableHeadersRow igTableHeadersRow;
            pImDrawList_AddNgonFilled ImDrawList_AddNgonFilled;
            pigDragScalar igDragScalar;
            pigSetCursorPos igSetCursorPos;
            pigGcCompactTransientMiscBuffers igGcCompactTransientMiscBuffers;
            pigEndColumns igEndColumns;
            pigSetTooltip igSetTooltip;
            pigTableGetColumnName_Int igTableGetColumnName_Int;
            pigTableGetColumnName_TablePtr igTableGetColumnName_TablePtr;
            pImGuiViewportP_destroy ImGuiViewportP_destroy;
            pigBeginTabBarEx igBeginTabBarEx;
            pigShadeVertsLinearColorGradientKeepAlpha igShadeVertsLinearColorGradientKeepAlpha;
            pImGuiInputTextState_HasSelection ImGuiInputTextState_HasSelection;
            pigCalcItemWidth igCalcItemWidth;
            pigPushItemWidth igPushItemWidth;
            pigScrollbarEx igScrollbarEx;
            pImDrawList_ChannelsMerge ImDrawList_ChannelsMerge;
            pigSetAllocatorFunctions igSetAllocatorFunctions;
            pImFont_FindGlyph ImFont_FindGlyph;
            pigDebugStartItemPicker igDebugStartItemPicker;
            pImGuiNextWindowData_destroy ImGuiNextWindowData_destroy;
            pImGuiPayload_IsDelivery ImGuiPayload_IsDelivery;
            pImFontAtlas_GetGlyphRangesJapanese ImFontAtlas_GetGlyphRangesJapanese;
            pImRect_Overlaps ImRect_Overlaps;
            pigCaptureMouseFromApp igCaptureMouseFromApp;
            pigAddContextHook igAddContextHook;
            pigImHashData igImHashData;
            pImGuiInputTextCallbackData_InsertChars ImGuiInputTextCallbackData_InsertChars;
            pigDragFloat2 igDragFloat2;
            pigTreePushOverrideID igTreePushOverrideID;
            pigUpdateHoveredWindowAndCaptureFlags igUpdateHoveredWindowAndCaptureFlags;
            pImFont_destroy ImFont_destroy;
            pigEndMenuBar igEndMenuBar;
            pigGetWindowSize igGetWindowSize;
            pigInputInt4 igInputInt4;
            pigImSign_Float igImSign_Float;
            pigImSign_double igImSign_double;
            pImDrawList_AddBezierQuadratic ImDrawList_AddBezierQuadratic;
            pigGetMouseCursor igGetMouseCursor;
            pigIsMouseDoubleClicked igIsMouseDoubleClicked;
            pigLabelText igLabelText;
            pImDrawList_PathClear ImDrawList_PathClear;
            pImDrawCmd_destroy ImDrawCmd_destroy;
            pigGetStateStorage igGetStateStorage;
            pigInputInt2 igInputInt2;
            pigImFileRead igImFileRead;
            pigImFontAtlasBuildRender32bppRectFromString igImFontAtlasBuildRender32bppRectFromString;
            pImGuiOldColumns_destroy ImGuiOldColumns_destroy;
            pigSetNextWindowScroll igSetNextWindowScroll;
            pigGetFrameHeight igGetFrameHeight;
            pigImFileWrite igImFileWrite;
            pigInputText igInputText;
            pigTreeNodeExV_Str igTreeNodeExV_Str;
            pigTreeNodeExV_Ptr igTreeNodeExV_Ptr;
            pigTableSetColumnSortDirection igTableSetColumnSortDirection;
            pigIsAnyItemFocused igIsAnyItemFocused;
            pImDrawDataBuilder_Clear ImDrawDataBuilder_Clear;
            pImVec2ih_ImVec2ih_Nil ImVec2ih_ImVec2ih_Nil;
            pImVec2ih_ImVec2ih_short ImVec2ih_ImVec2ih_short;
            pImVec2ih_ImVec2ih_Vec2 ImVec2ih_ImVec2ih_Vec2;
            pigPopStyleColor igPopStyleColor;
            pImVec1_ImVec1_Nil ImVec1_ImVec1_Nil;
            pImVec1_ImVec1_Float ImVec1_ImVec1_Float;
            pigCalcItemSize igCalcItemSize;
            pImFontAtlasCustomRect_IsPacked ImFontAtlasCustomRect_IsPacked;
            pigColorEdit4 igColorEdit4;
            pigPlotEx igPlotEx;
            pigGetCursorStartPos igGetCursorStartPos;
            pImGuiInputTextCallbackData_destroy ImGuiInputTextCallbackData_destroy;
            pImFontAtlas_IsBuilt ImFontAtlas_IsBuilt;
            pImGuiTextBuffer_begin ImGuiTextBuffer_begin;
            pImGuiTable_destroy ImGuiTable_destroy;
            pImGuiWindow_GetIDNoKeepAlive_Str ImGuiWindow_GetIDNoKeepAlive_Str;
            pImGuiWindow_GetIDNoKeepAlive_Ptr ImGuiWindow_GetIDNoKeepAlive_Ptr;
            pImGuiWindow_GetIDNoKeepAlive_Int ImGuiWindow_GetIDNoKeepAlive_Int;
            pImFont_BuildLookupTable ImFont_BuildLookupTable;
            pImGuiTextBuffer_appendfv ImGuiTextBuffer_appendfv;
            pImVec4_ImVec4_Nil ImVec4_ImVec4_Nil;
            pImVec4_ImVec4_Float ImVec4_ImVec4_Float;
            pigClearIniSettings igClearIniSettings;
            pigImTextCountCharsFromUtf8 igImTextCountCharsFromUtf8;
            pImDrawList_PathLineToMergeDuplicate ImDrawList_PathLineToMergeDuplicate;
            pImGuiIO_ImGuiIO ImGuiIO_ImGuiIO;
            pigDragInt4 igDragInt4;
            pigBeginDragDropTarget igBeginDragDropTarget;
            pigTablePopBackgroundChannel igTablePopBackgroundChannel;
            pImGuiTextBuffer_clear ImGuiTextBuffer_clear;
            pigImStricmp igImStricmp;
            pigMarkItemEdited igMarkItemEdited;
            pigIsWindowFocused igIsWindowFocused;
            pigTableSettingsCreate igTableSettingsCreate;
            pImGuiIO_AddInputCharactersUTF8 ImGuiIO_AddInputCharactersUTF8;
            pImGuiTableSettings_destroy ImGuiTableSettings_destroy;
            pigIsWindowAbove igIsWindowAbove;
            pImDrawList__PathArcToN ImDrawList__PathArcToN;
            pigColorTooltip igColorTooltip;
            pigSetCurrentContext igSetCurrentContext;
            pigImTriangleClosestPoint igImTriangleClosestPoint;
            pigSliderInt4 igSliderInt4;
            pigGetItemRectMin igGetItemRectMin;
            pigTableUpdateColumnsWeightFromWidth igTableUpdateColumnsWeightFromWidth;
            pImDrawList_PrimReserve ImDrawList_PrimReserve;
            pImGuiMenuColumns_ImGuiMenuColumns ImGuiMenuColumns_ImGuiMenuColumns;
            pImDrawList_AddRectFilledMultiColor ImDrawList_AddRectFilledMultiColor;
            pigImPow_Float igImPow_Float;
            pigImPow_double igImPow_double;
            pigSeparatorEx igSeparatorEx;
            pigSetStateStorage igSetStateStorage;
            pImGuiStorage_SetAllInt ImGuiStorage_SetAllInt;
            pImGuiListClipper_Step ImGuiListClipper_Step;
            pImGuiOnceUponAFrame_destroy ImGuiOnceUponAFrame_destroy;
            pImGuiInputTextCallbackData_DeleteChars ImGuiInputTextCallbackData_DeleteChars;
            pigImFontAtlasBuildSetupFont igImFontAtlasBuildSetupFont;
            pImGuiTextBuffer_empty ImGuiTextBuffer_empty;
            pigShowDemoWindow igShowDemoWindow;
            pImGuiTextRange_destroy ImGuiTextRange_destroy;
            pImGuiStorage_SetVoidPtr ImGuiStorage_SetVoidPtr;
            pigImInvLength igImInvLength;
            pigGetFocusScope igGetFocusScope;
            pigCloseButton igCloseButton;
            pigTableSettingsInstallHandler igTableSettingsInstallHandler;
            pImDrawList_PushTextureID ImDrawList_PushTextureID;
            pImDrawList_PathLineTo ImDrawList_PathLineTo;
            pigSetWindowHitTestHole igSetWindowHitTestHole;
            pImRect_Add_Vec2 ImRect_Add_Vec2;
            pImRect_Add_Rect ImRect_Add_Rect;
            pigShowMetricsWindow igShowMetricsWindow;
            pImDrawList__PopUnusedDrawCmd ImDrawList__PopUnusedDrawCmd;
            pImDrawList_AddImageRounded ImDrawList_AddImageRounded;
            pImGuiStyleMod_destroy ImGuiStyleMod_destroy;
            pImGuiStorage_BuildSortByKey ImGuiStorage_BuildSortByKey;
            pigTableSetupDrawChannels igTableSetupDrawChannels;
            pImDrawList_PathRect ImDrawList_PathRect;
            pigInputTextEx igInputTextEx;
            pigColorEdit3 igColorEdit3;
            pImColor_destroy ImColor_destroy;
            pigIsItemToggledSelection igIsItemToggledSelection;
            pigTabItemEx igTabItemEx;
            pigIsKeyPressedMap igIsKeyPressedMap;
            pigLogFinish igLogFinish;
            pigGetItemRectSize igGetItemRectSize;
            pigImParseFormatFindStart igImParseFormatFindStart;
            pigDragScalarN igDragScalarN;
            pImDrawData_ImDrawData ImDrawData_ImDrawData;
            pigImDot igImDot;
            pigMarkIniSettingsDirty_Nil igMarkIniSettingsDirty_Nil;
            pigMarkIniSettingsDirty_WindowPtr igMarkIniSettingsDirty_WindowPtr;
            pigTableGetColumnCount igTableGetColumnCount;
            pigGetWindowWidth igGetWindowWidth;
            pigBulletTextV igBulletTextV;
            pigPushTextWrapPos igPushTextWrapPos;
            pImDrawListSplitter_SetCurrentChannel ImDrawListSplitter_SetCurrentChannel;
            pImGuiStorage_SetBool ImGuiStorage_SetBool;
            pigAlignTextToFramePadding igAlignTextToFramePadding;
            pigIsWindowHovered igIsWindowHovered;
            pImRect_GetCenter ImRect_GetCenter;
            pigGetWindowContentRegionWidth igGetWindowContentRegionWidth;
            pImDrawList_PathArcTo ImDrawList_PathArcTo;
            pigIsAnyItemActive igIsAnyItemActive;
            pigStyleColorsDark igStyleColorsDark;
            pigGetTreeNodeToLabelSpacing igGetTreeNodeToLabelSpacing;
            pigSameLine igSameLine;
            pigTabBarQueueReorder igTabBarQueueReorder;
            pigDummy igDummy;
            pigGetItemID igGetItemID;
            pigImageButton igImageButton;
            pigGetWindowContentRegionMax igGetWindowContentRegionMax;
            pigGetKeyPressedAmount igGetKeyPressedAmount;
            pigRenderTextClipped igRenderTextClipped;
            pigImIsPowerOfTwo_Int igImIsPowerOfTwo_Int;
            pigImIsPowerOfTwo_U64 igImIsPowerOfTwo_U64;
            pigSetNextWindowSizeConstraints igSetNextWindowSizeConstraints;
            pigTableGcCompactTransientBuffers igTableGcCompactTransientBuffers;
            pImFont_FindGlyphNoFallback ImFont_FindGlyphNoFallback;
            pigShowStyleSelector igShowStyleSelector;
            pigFocusableItemUnregister igFocusableItemUnregister;
            pigNavMoveRequestForward igNavMoveRequestForward;
            pigNavInitWindow igNavInitWindow;
            pigImFileOpen igImFileOpen;
            pigEndDragDropTarget igEndDragDropTarget;
            pImGuiWindowSettings_ImGuiWindowSettings ImGuiWindowSettings_ImGuiWindowSettings;
            pImDrawListSharedData_destroy ImDrawListSharedData_destroy;
            pImFontAtlas_Build ImFontAtlas_Build;
            pigSetScrollFromPosX_Float igSetScrollFromPosX_Float;
            pigSetScrollFromPosX_WindowPtr igSetScrollFromPosX_WindowPtr;
            pigIsKeyPressed igIsKeyPressed;
            pigEndTooltip igEndTooltip;
            pigFindWindowSettings igFindWindowSettings;
            pigDebugRenderViewportThumbnail igDebugRenderViewportThumbnail;
            pigKeepAliveID igKeepAliveID;
            pigGetColumnOffsetFromNorm igGetColumnOffsetFromNorm;
            pImFont_IsLoaded ImFont_IsLoaded;
            pigDebugNodeDrawCmdShowMeshAndBoundingBox igDebugNodeDrawCmdShowMeshAndBoundingBox;
            pigBeginDragDropSource igBeginDragDropSource;
            pImBitVector_ClearBit ImBitVector_ClearBit;
            pImDrawDataBuilder_GetDrawListCount ImDrawDataBuilder_GetDrawListCount;
            pigGetCursorPosX igGetCursorPosX;
            pigSetScrollFromPosY_Float igSetScrollFromPosY_Float;
            pigSetScrollFromPosY_WindowPtr igSetScrollFromPosY_WindowPtr;
            pigColorButton igColorButton;
            pigAcceptDragDropPayload igAcceptDragDropPayload;
            pImDrawList_PopClipRect ImDrawList_PopClipRect;
            pigPushFont igPushFont;
            pigGetScrollMaxY igGetScrollMaxY;
            pImGuiStoragePair_ImGuiStoragePair_Int ImGuiStoragePair_ImGuiStoragePair_Int;
            pImGuiStoragePair_ImGuiStoragePair_Float ImGuiStoragePair_ImGuiStoragePair_Float;
            pImGuiStoragePair_ImGuiStoragePair_Ptr ImGuiStoragePair_ImGuiStoragePair_Ptr;
            pigEndMainMenuBar igEndMainMenuBar;
            pImGuiViewportP_GetMainRect ImGuiViewportP_GetMainRect;
            pImRect_GetArea ImRect_GetArea;
            pigIsItemActive igIsItemActive;
            pigShowAboutWindow igShowAboutWindow;
            pigSetNextItemWidth igSetNextItemWidth;
            pigImStrchrRange igImStrchrRange;
            pigGetContentRegionAvail igGetContentRegionAvail;
            pImGuiPayload_ImGuiPayload ImGuiPayload_ImGuiPayload;
            pigCheckbox igCheckbox;
            pImGuiTextRange_ImGuiTextRange_Nil ImGuiTextRange_ImGuiTextRange_Nil;
            pImGuiTextRange_ImGuiTextRange_Str ImGuiTextRange_ImGuiTextRange_Str;
            pImFontAtlas_destroy ImFontAtlas_destroy;
            pImGuiMenuColumns_Update ImGuiMenuColumns_Update;
            pigGcCompactTransientWindowBuffers igGcCompactTransientWindowBuffers;
            pigTableSortSpecsBuild igTableSortSpecsBuild;
            pigNavMoveRequestTryWrapping igNavMoveRequestTryWrapping;
            pigGetCurrentWindow igGetCurrentWindow;
            pigPushStyleColor_U32 igPushStyleColor_U32;
            pigPushStyleColor_Vec4 igPushStyleColor_Vec4;
            pImVec2_destroy ImVec2_destroy;
            pigTableBeginRow igTableBeginRow;
            pigGetID_Str igGetID_Str;
            pigGetID_StrStr igGetID_StrStr;
            pigGetID_Ptr igGetID_Ptr;
            pigSetDragDropPayload igSetDragDropPayload;
            pigImFontAtlasBuildMultiplyCalcLookupTable igImFontAtlasBuildMultiplyCalcLookupTable;
            pImFontAtlas_ImFontAtlas ImFontAtlas_ImFontAtlas;
            pImGuiMenuColumns_CalcExtraSpace ImGuiMenuColumns_CalcExtraSpace;
            pigGetContentRegionMax igGetContentRegionMax;
            pigBeginGroup igBeginGroup;
            pigActivateItem igActivateItem;
            pigPopStyleVar igPopStyleVar;
            pImDrawList_PushClipRectFullScreen ImDrawList_PushClipRectFullScreen;
            pImRect_Contains_Vec2 ImRect_Contains_Vec2;
            pImRect_Contains_Rect ImRect_Contains_Rect;
            pigEndChildFrame igEndChildFrame;
            pigSetColumnOffset igSetColumnOffset;
            pigSetKeyboardFocusHere igSetKeyboardFocusHere;
            pigLoadIniSettingsFromMemory igLoadIniSettingsFromMemory;
            pigGetBackgroundDrawList_Nil igGetBackgroundDrawList_Nil;
            pigGetBackgroundDrawList_ViewportPtr igGetBackgroundDrawList_ViewportPtr;
            pigSetNextWindowSize igSetNextWindowSize;
            pigInputFloat3 igInputFloat3;
            pigIndent igIndent;
            pigTableBeginApplyRequests igTableBeginApplyRequests;
            pigIsKeyDown igIsKeyDown;
            pigTextUnformatted igTextUnformatted;
            pigTextV igTextV;
            pigImLengthSqr_Vec2 igImLengthSqr_Vec2;
            pigImLengthSqr_Vec4 igImLengthSqr_Vec4;
            pImGuiTextFilter_Draw ImGuiTextFilter_Draw;
            pigFocusWindow igFocusWindow;
            pigPushClipRect igPushClipRect;
            pImGuiViewportP_ImGuiViewportP ImGuiViewportP_ImGuiViewportP;
            pigBeginMainMenuBar igBeginMainMenuBar;
            pImRect_GetBR ImRect_GetBR;
            pigCollapsingHeader_TreeNodeFlags igCollapsingHeader_TreeNodeFlags;
            pigCollapsingHeader_BoolPtr igCollapsingHeader_BoolPtr;
            pigGetCurrentWindowRead igGetCurrentWindowRead;
            pImDrawList__PathArcToFastEx ImDrawList__PathArcToFastEx;
            pigSliderInt3 igSliderInt3;
            pigGetItemsFlags igGetItemsFlags;
            pImGuiTableSettings_ImGuiTableSettings ImGuiTableSettings_ImGuiTableSettings;
            pigImFormatString igImFormatString;
            pigTabItemButton igTabItemButton;
            pigIsMouseReleased igIsMouseReleased;
            pImGuiInputTextState_CursorClamp ImGuiInputTextState_CursorClamp;
            pigRemoveContextHook igRemoveContextHook;
            pImFontAtlasCustomRect_ImFontAtlasCustomRect ImFontAtlasCustomRect_ImFontAtlasCustomRect;
            pImGuiIO_AddInputCharacter ImGuiIO_AddInputCharacter;
            pigTabBarProcessReorder igTabBarProcessReorder;
            pigGetNavInputAmount igGetNavInputAmount;
            pigClearDragDrop igClearDragDrop;
            pigGetTextLineHeight igGetTextLineHeight;
            pImDrawList_AddBezierCubic ImDrawList_AddBezierCubic;
            pigDataTypeApplyOp igDataTypeApplyOp;
            pImDrawList_AddQuadFilled ImDrawList_AddQuadFilled;
            pigSetNextWindowBgAlpha igSetNextWindowBgAlpha;
            pImGuiInputTextCallbackData_SelectAll ImGuiInputTextCallbackData_SelectAll;
            pImGuiNextItemData_ImGuiNextItemData ImGuiNextItemData_ImGuiNextItemData;
            pigLogRenderedText igLogRenderedText;
            pigBeginMenu igBeginMenu;
            pImGuiStorage_GetIntRef ImGuiStorage_GetIntRef;
            pigImTextCountUtf8BytesFromStr igImTextCountUtf8BytesFromStr;
            pigEndCombo igEndCombo;
            pigIsNavInputTest igIsNavInputTest;
            pigImage igImage;
            pImDrawList_AddPolyline ImDrawList_AddPolyline;
            pigTreeNode_Str igTreeNode_Str;
            pigTreeNode_StrStr igTreeNode_StrStr;
            pigTreeNode_Ptr igTreeNode_Ptr;
            pigPopClipRect igPopClipRect;
            pImDrawList_PushClipRect ImDrawList_PushClipRect;
            pigImBitArrayClearBit igImBitArrayClearBit;
            pigArrowButtonEx igArrowButtonEx;
            pigSelectable_Bool igSelectable_Bool;
            pigSelectable_BoolPtr igSelectable_BoolPtr;
            pigTableSetColumnWidthAutoSingle igTableSetColumnWidthAutoSingle;
            pigBeginTooltipEx igBeginTooltipEx;
            pigGetFocusID igGetFocusID;
            pImDrawData_DeIndexAllBuffers ImDrawData_DeIndexAllBuffers;
            pImDrawCmd_ImDrawCmd ImDrawCmd_ImDrawCmd;
            pImDrawData_ScaleClipRects ImDrawData_ScaleClipRects;
            pigSetNextItemOpen igSetNextItemOpen;
            pigDataTypeFormatString igDataTypeFormatString;
            pigTabItemBackground igTabItemBackground;
            pImDrawList_AddTriangle ImDrawList_AddTriangle;
            pigLogToFile igLogToFile;
            pImGuiContextHook_destroy ImGuiContextHook_destroy;
            pigTempInputIsActive igTempInputIsActive;
            pImGuiNextItemData_destroy ImGuiNextItemData_destroy;
            pigGetMergedKeyModFlags igGetMergedKeyModFlags;
            pigDebugNodeWindowSettings igDebugNodeWindowSettings;
            pImRect_ToVec4 ImRect_ToVec4;
            pigTableGcCompactSettings igTableGcCompactSettings;
            pigPushMultiItemsWidths igPushMultiItemsWidths;
            pigCreateContext igCreateContext;
            pigTableNextRow igTableNextRow;
            pImGuiStackSizes_CompareWithCurrentState ImGuiStackSizes_CompareWithCurrentState;
            pImColor_ImColor_Nil ImColor_ImColor_Nil;
            pImColor_ImColor_Int ImColor_ImColor_Int;
            pImColor_ImColor_U32 ImColor_ImColor_U32;
            pImColor_ImColor_Float ImColor_ImColor_Float;
            pImColor_ImColor_Vec4 ImColor_ImColor_Vec4;
            pigTableGetMaxColumnWidth igTableGetMaxColumnWidth;
            pImDrawList__ClearFreeMemory ImDrawList__ClearFreeMemory;
            pigSetNavID igSetNavID;
            pigGetWindowDrawList igGetWindowDrawList;
            pImRect_GetBL ImRect_GetBL;
            pigTableGetHeaderRowHeight igTableGetHeaderRowHeight;
            pigIsMousePosValid igIsMousePosValid;
            pImGuiStorage_GetFloat ImGuiStorage_GetFloat;
            pigTableEndCell igTableEndCell;
            pigSliderFloat4 igSliderFloat4;
            pigIsItemDeactivatedAfterEdit igIsItemDeactivatedAfterEdit;
            pigPlotHistogram_FloatPtr igPlotHistogram_FloatPtr;
            pigPlotHistogram_FnFloatPtr igPlotHistogram_FnFloatPtr;
            pigIsItemEdited igIsItemEdited;
            pigShowStyleEditor igShowStyleEditor;
            pigTextWrappedV igTextWrappedV;
            pigTableBeginCell igTableBeginCell;
            pigTableGetColumnNextSortDirection igTableGetColumnNextSortDirection;
            pImGuiLastItemDataBackup_destroy ImGuiLastItemDataBackup_destroy;
            pImGuiTextBuffer_appendf ImGuiTextBuffer_appendf;
            pImFontAtlas_AddCustomRectFontGlyph ImFontAtlas_AddCustomRectFontGlyph;
            pigDebugCheckVersionAndDataLayout igDebugCheckVersionAndDataLayout;
            pigImAlphaBlendColors igImAlphaBlendColors;
            pImGuiStorage_GetBoolRef ImGuiStorage_GetBoolRef;
            pigBeginPopupContextVoid igBeginPopupContextVoid;
            pigSetScrollX_Float igSetScrollX_Float;
            pigSetScrollX_WindowPtr igSetScrollX_WindowPtr;
            pigRenderNavHighlight igRenderNavHighlight;
            pigBringWindowToFocusFront igBringWindowToFocusFront;
            pigSliderInt igSliderInt;
            pigUpdateMouseMovingWindowEndFrame igUpdateMouseMovingWindowEndFrame;
            pigInputTextWithHint igInputTextWithHint;
            pigGetContentRegionMaxAbs igGetContentRegionMaxAbs;
            pigIsMouseHoveringRect igIsMouseHoveringRect;
            pImGuiLastItemDataBackup_Backup ImGuiLastItemDataBackup_Backup;
            pigImTextStrFromUtf8 igImTextStrFromUtf8;
            pigIsActiveIdUsingNavDir igIsActiveIdUsingNavDir;
            pImGuiListClipper_Begin ImGuiListClipper_Begin;
            pigStartMouseMovingWindow igStartMouseMovingWindow;
            pigSliderInt2 igSliderInt2;
            pigIsItemHovered igIsItemHovered;
            pigTableEndRow igTableEndRow;
            pImGuiIO_destroy ImGuiIO_destroy;
            pigEndDragDropSource igEndDragDropSource;
            pImGuiStackSizes_SetToCurrentState ImGuiStackSizes_SetToCurrentState;
            pigGetDragDropPayload igGetDragDropPayload;
            pigPopButtonRepeat igPopButtonRepeat;
            pImGuiStorage_SetInt ImGuiStorage_SetInt;
            pImGuiWindow_MenuBarRect ImGuiWindow_MenuBarRect;
            pImGuiStorage_GetInt ImGuiStorage_GetInt;
            pigShowFontSelector igShowFontSelector;
            pigImMin igImMin;
            pigPushButtonRepeat igPushButtonRepeat;
            pigTableSetColumnWidthAutoAll igTableSetColumnWidthAutoAll;
            pigImAbs_Float igImAbs_Float;
            pigImAbs_double igImAbs_double;
            pImGuiWindow_Rect ImGuiWindow_Rect;
            pImGuiViewportP_GetWorkRect ImGuiViewportP_GetWorkRect;
            pImRect_Floor ImRect_Floor;
            pigTreePush_Str igTreePush_Str;
            pigTreePush_Ptr igTreePush_Ptr;
            pigColorConvertFloat4ToU32 igColorConvertFloat4ToU32;
            pigGetStyle igGetStyle;
            pigGetCursorPos igGetCursorPos;
            pigGetFrameCount igGetFrameCount;
            pImDrawList_AddNgon ImDrawList_AddNgon;
            pigDebugNodeDrawList igDebugNodeDrawList;
            pigEnd igEnd;
            pigTabBarCloseTab igTabBarCloseTab;
            pigIsItemActivated igIsItemActivated;
            pImGuiInputTextState_ImGuiInputTextState ImGuiInputTextState_ImGuiInputTextState;
            pImRect_GetHeight ImRect_GetHeight;
            pImFontAtlas_AddFontDefault ImFontAtlas_AddFontDefault;
            pImDrawList__OnChangedTextureID ImDrawList__OnChangedTextureID;
            pigGetColumnsCount igGetColumnsCount;
            pigEndChild igEndChild;
            pigNavMoveRequestButNoResultYet igNavMoveRequestButNoResultYet;
            pImGuiStyle_ScaleAllSizes ImGuiStyle_ScaleAllSizes;
            pigArrowButton igArrowButton;
            pigSetCursorPosY igSetCursorPosY;
            pImGuiTextFilter_ImGuiTextFilter ImGuiTextFilter_ImGuiTextFilter;
            pImGuiStorage_SetFloat ImGuiStorage_SetFloat;
            pigShadeVertsLinearUV igShadeVertsLinearUV;
            pigTableGetColumnIndex igTableGetColumnIndex;
            pigGetTime igGetTime;
            pigBeginPopupContextItem igBeginPopupContextItem;
            pigTableLoadSettings igTableLoadSettings;
            pigSetScrollHereX igSetScrollHereX;
            pigSliderScalarN igSliderScalarN;
            pImDrawList_PathBezierQuadraticCurveTo ImDrawList_PathBezierQuadraticCurveTo;
            pImFontAtlas_GetGlyphRangesChineseSimplifiedCommon ImFontAtlas_GetGlyphRangesChineseSimplifiedCommon;
            pigGetMousePosOnOpeningCurrentPopup igGetMousePosOnOpeningCurrentPopup;
            pigVSliderScalar igVSliderScalar;
            pImFont_RenderChar ImFont_RenderChar;
            pImFont_RenderText ImFont_RenderText;
            pigOpenPopupEx igOpenPopupEx;
            pImFontAtlas_SetTexID ImFontAtlas_SetTexID;
            pigImFontAtlasBuildRender8bppRectFromString igImFontAtlasBuildRender8bppRectFromString;
            pImFontAtlas_Clear ImFontAtlas_Clear;
            pImBitVector_TestBit ImBitVector_TestBit;
            pImGuiTextFilter_destroy ImGuiTextFilter_destroy;
            pigBeginPopupModal igBeginPopupModal;
            pigGetFocusedFocusScope igGetFocusedFocusScope;
            pigDebugNodeColumns igDebugNodeColumns;
            pigDebugNodeWindow igDebugNodeWindow;
            pigInputFloat igInputFloat;
            pigDragIntRange2 igDragIntRange2;
            pImVec2ih_destroy ImVec2ih_destroy;
            pImDrawList_GetClipRectMax ImDrawList_GetClipRectMax;
            pigInputFloat2 igInputFloat2;
            pImDrawDataBuilder_ClearFreeMemory ImDrawDataBuilder_ClearFreeMemory;
            pImGuiWindowSettings_GetName ImGuiWindowSettings_GetName;
            pImGuiLastItemDataBackup_Restore ImGuiLastItemDataBackup_Restore;
            pigImStrdup igImStrdup;
            pigImFormatStringV igImFormatStringV;
            pigSetTooltipV igSetTooltipV;
            pigDataTypeGetInfo igDataTypeGetInfo;
            pigVSliderInt igVSliderInt;
            pigSetWindowClipRectBeforeSetChannel igSetWindowClipRectBeforeSetChannel;
            pImFontGlyphRangesBuilder_ImFontGlyphRangesBuilder ImFontGlyphRangesBuilder_ImFontGlyphRangesBuilder;
            pigPopTextWrapPos igPopTextWrapPos;
            pImGuiWindow_TitleBarHeight ImGuiWindow_TitleBarHeight;
            pImDrawList_GetClipRectMin ImDrawList_GetClipRectMin;
            pImDrawList_PathStroke ImDrawList_PathStroke;
            pigBeginTooltip igBeginTooltip;
            pigOpenPopupOnItemClick igOpenPopupOnItemClick;
            pImDrawListSplitter_Merge ImDrawListSplitter_Merge;
            pImGuiWindow_MenuBarHeight ImGuiWindow_MenuBarHeight;
            pImColor_HSV ImColor_HSV;
            pigBeginTableEx igBeginTableEx;
            pigSetTabItemClosed igSetTabItemClosed;
            pImFont_AddGlyph ImFont_AddGlyph;
            pigSetHoveredID igSetHoveredID;
            pImFontGlyphRangesBuilder_AddText ImFontGlyphRangesBuilder_AddText;
            pImGuiPtrOrIndex_destroy ImGuiPtrOrIndex_destroy;
            pImGuiInputTextCallbackData_ImGuiInputTextCallbackData ImGuiInputTextCallbackData_ImGuiInputTextCallbackData;
            pigImStrdupcpy igImStrdupcpy;
            pigColorPicker4 igColorPicker4;
            pigColorConvertHSVtoRGB igColorConvertHSVtoRGB;
            pigImBitArrayTestBit igImBitArrayTestBit;
            pigFindWindowByID igFindWindowByID;
            pImDrawList_PathBezierCubicCurveTo ImDrawList_PathBezierCubicCurveTo;
            pigBeginDragDropTargetCustom igBeginDragDropTargetCustom;
            pImGuiContext_destroy ImGuiContext_destroy;
            pigDragInt3 igDragInt3;
            pigImHashStr igImHashStr;
            pImDrawList_AddTriangleFilled ImDrawList_AddTriangleFilled;
            pigTempInputScalar igTempInputScalar;
            pigRenderArrow igRenderArrow;
            pigNewFrame igNewFrame;
            pImDrawList_ChannelsSetCurrent ImDrawList_ChannelsSetCurrent;
            pImGuiTabItem_ImGuiTabItem ImGuiTabItem_ImGuiTabItem;
            pImGuiContext_ImGuiContext ImGuiContext_ImGuiContext;
            pigClosePopupToLevel igClosePopupToLevel;
            pigSliderFloat2 igSliderFloat2;
            pImGuiPopupData_ImGuiPopupData ImGuiPopupData_ImGuiPopupData;
            pImDrawList_AddImageQuad ImDrawList_AddImageQuad;
            pigBeginListBox igBeginListBox;
            pImFontAtlas_GetCustomRectByIndex ImFontAtlas_GetCustomRectByIndex;
            pImFontAtlas_GetTexDataAsAlpha8 ImFontAtlas_GetTexDataAsAlpha8;
            pigGcAwakeTransientWindowBuffers igGcAwakeTransientWindowBuffers;
            pImDrawList__OnChangedClipRect ImDrawList__OnChangedClipRect;
            pigGetColumnsID igGetColumnsID;
            pigGetCursorScreenPos igGetCursorScreenPos;
            pigPushAllowKeyboardFocus igPushAllowKeyboardFocus;
            pImDrawList_PopTextureID ImDrawList_PopTextureID;
            pigColumns igColumns;
            pImFontGlyphRangesBuilder_AddChar ImFontGlyphRangesBuilder_AddChar;
            pigGetColumnIndex igGetColumnIndex;
            pigBringWindowToDisplayBack igBringWindowToDisplayBack;
            pImDrawList_PrimVtx ImDrawList_PrimVtx;
            pImDrawListSplitter_Clear ImDrawListSplitter_Clear;
            pigTableBeginInitMemory igTableBeginInitMemory;
            pImDrawList_AddConvexPolyFilled ImDrawList_AddConvexPolyFilled;
            pigListBox_Str_arr igListBox_Str_arr;
            pigListBox_FnBoolPtr igListBox_FnBoolPtr;
            pigPopItemFlag igPopItemFlag;
            pigImBezierCubicClosestPoint igImBezierCubicClosestPoint;
            pigPopColumnsBackground igPopColumnsBackground;
            pigLogBegin igLogBegin;
            pigTreeNodeV_Str igTreeNodeV_Str;
            pigTreeNodeV_Ptr igTreeNodeV_Ptr;
            pigRenderTextClippedEx igRenderTextClippedEx;
            pigTableSettingsFindByID igTableSettingsFindByID;
            pImGuiIO_AddInputCharacterUTF16 ImGuiIO_AddInputCharacterUTF16;
            pImGuiStorage_GetFloatRef ImGuiStorage_GetFloatRef;
            pigImStrbolW igImStrbolW;
            pImGuiStackSizes_ImGuiStackSizes ImGuiStackSizes_ImGuiStackSizes;
            pigSliderBehavior igSliderBehavior;
            pigValue_Bool igValue_Bool;
            pigValue_Int igValue_Int;
            pigValue_Uint igValue_Uint;
            pigValue_Float igValue_Float;
            pigBeginTabItem igBeginTabItem;
            pigDebugNodeTable igDebugNodeTable;
            pImGuiViewport_destroy ImGuiViewport_destroy;
            pigIsNavInputDown igIsNavInputDown;
            pImGuiInputTextState_ClearFreeMemory ImGuiInputTextState_ClearFreeMemory;
            pImGuiViewport_GetWorkCenter ImGuiViewport_GetWorkCenter;
            pigRenderBullet igRenderBullet;
            pigDragFloat4 igDragFloat4;
            pImDrawList__OnChangedVtxOffset ImDrawList__OnChangedVtxOffset;
            pigTableSortSpecsSanitize igTableSortSpecsSanitize;
            pigFocusTopMostWindowUnderOne igFocusTopMostWindowUnderOne;
            pigPushID_Str igPushID_Str;
            pigPushID_StrStr igPushID_StrStr;
            pigPushID_Ptr igPushID_Ptr;
            pigPushID_Int igPushID_Int;
            pigItemHoverable igItemHoverable;
            pImFontAtlas_AddFontFromMemoryTTF ImFontAtlas_AddFontFromMemoryTTF;
            pigImFontAtlasBuildMultiplyRectAlpha8 igImFontAtlasBuildMultiplyRectAlpha8;
            pigTextDisabledV igTextDisabledV;
            pigInputScalar igInputScalar;
            pImGuiPtrOrIndex_ImGuiPtrOrIndex_Ptr ImGuiPtrOrIndex_ImGuiPtrOrIndex_Ptr;
            pImGuiPtrOrIndex_ImGuiPtrOrIndex_Int ImGuiPtrOrIndex_ImGuiPtrOrIndex_Int;
            pigImLerp_Vec2Float igImLerp_Vec2Float;
            pigImLerp_Vec2Vec2 igImLerp_Vec2Vec2;
            pigImLerp_Vec4 igImLerp_Vec4;
            pigItemSize_Vec2 igItemSize_Vec2;
            pigItemSize_Rect igItemSize_Rect;
            pImColor_SetHSV ImColor_SetHSV;
            pImFont_IsGlyphRangeUnused ImFont_IsGlyphRangeUnused;
            pigImBezierQuadraticCalc igImBezierQuadraticCalc;
            pigImParseFormatPrecision igImParseFormatPrecision;
            pigLogToTTY igLogToTTY;
            pigTableGetColumnWidthAuto igTableGetColumnWidthAuto;
            pigButtonBehavior igButtonBehavior;
            pImGuiInputTextState_OnKeyPressed ImGuiInputTextState_OnKeyPressed;
            pigImLog_Float igImLog_Float;
            pigImLog_double igImLog_double;
            pigSetFocusID igSetFocusID;
            pigGetActiveID igGetActiveID;
            pigImLineClosestPoint igImLineClosestPoint;
            pigIsItemVisible igIsItemVisible;
            pigRender igRender;
            pigImTriangleArea igImTriangleArea;
            pigBeginChild_Str igBeginChild_Str;
            pigBeginChild_ID igBeginChild_ID;
            pigStyleColorsLight igStyleColorsLight;
            pigGetScrollX igGetScrollX;
            pigGetWindowAllowedExtentRect igGetWindowAllowedExtentRect;
            pigCallContextHooks igCallContextHooks;
            pImFontAtlas_GetTexDataAsRGBA32 ImFontAtlas_GetTexDataAsRGBA32;
            pImGuiOnceUponAFrame_ImGuiOnceUponAFrame ImGuiOnceUponAFrame_ImGuiOnceUponAFrame;
            pImDrawData_destroy ImDrawData_destroy;
            pImFont_SetFallbackChar ImFont_SetFallbackChar;
            pigSaveIniSettingsToMemory igSaveIniSettingsToMemory;
            pImGuiNavMoveResult_ImGuiNavMoveResult ImGuiNavMoveResult_ImGuiNavMoveResult;
            pigTabBarRemoveTab igTabBarRemoveTab;
            pigGetWindowHeight igGetWindowHeight;
            pigGetMainViewport igGetMainViewport;
            pImGuiTextFilter_PassFilter ImGuiTextFilter_PassFilter;
            pImFontAtlas_AddFontFromMemoryCompressedBase85TTF ImFontAtlas_AddFontFromMemoryCompressedBase85TTF;
            pImFontAtlas_AddFontFromFileTTF ImFontAtlas_AddFontFromFileTTF;
            pigGetCurrentContext igGetCurrentContext;
            pigColorConvertU32ToFloat4 igColorConvertU32ToFloat4;
            pImDrawList_PathArcToFast ImDrawList_PathArcToFast;
            pigDragFloat igDragFloat;
            pigGetStyleColorName igGetStyleColorName;
            pigSetItemDefaultFocus igSetItemDefaultFocus;
            pigCalcListClipping igCalcListClipping;
            pigSetNextWindowPos igSetNextWindowPos;
            pigDragFloat3 igDragFloat3;
            pigCaptureKeyboardFromApp igCaptureKeyboardFromApp;
            pigGetCurrentTable igGetCurrentTable;
            pImDrawData_Clear ImDrawData_Clear;
            pImFontAtlas_AddFontFromMemoryCompressedTTF ImFontAtlas_AddFontFromMemoryCompressedTTF;
            pImGuiStoragePair_destroy ImGuiStoragePair_destroy;
            pigIsItemToggledOpen igIsItemToggledOpen;
            pigInputInt3 igInputInt3;
            pigShrinkWidths igShrinkWidths;
            pImDrawList_AddText_Vec2 ImDrawList_AddText_Vec2;
            pImDrawList_AddText_FontPtr ImDrawList_AddText_FontPtr;
            pImDrawList_PrimRectUV ImDrawList_PrimRectUV;
            pImDrawList_PrimWriteIdx ImDrawList_PrimWriteIdx;
            pImGuiOldColumns_ImGuiOldColumns ImGuiOldColumns_ImGuiOldColumns;
            pigTableRemove igTableRemove;
            pigDebugNodeTableSettings igDebugNodeTableSettings;
            pImGuiStorage_GetBool ImGuiStorage_GetBool;
            pigRenderFrameBorder igRenderFrameBorder;
            pigFindWindowByName igFindWindowByName;
            pigImTextStrToUtf8 igImTextStrToUtf8;
            pigTextWrapped igTextWrapped;
            pigScrollToBringRectIntoView igScrollToBringRectIntoView;
            pigInputInt igInputInt;
            pImVec2_ImVec2_Nil ImVec2_ImVec2_Nil;
            pImVec2_ImVec2_Float ImVec2_ImVec2_Float;
            pImGuiTextBuffer_size ImGuiTextBuffer_size;
            pImFontAtlas_GetGlyphRangesDefault ImFontAtlas_GetGlyphRangesDefault;
            pImFontAtlas_ClearTexData ImFontAtlas_ClearTexData;
            pImFont_GetCharAdvance ImFont_GetCharAdvance;
            pigSliderFloat3 igSliderFloat3;
            pImDrawList_PathFillConvex ImDrawList_PathFillConvex;
            pImGuiTextBuffer_ImGuiTextBuffer ImGuiTextBuffer_ImGuiTextBuffer;
            pImGuiTabItem_destroy ImGuiTabItem_destroy;
            pigSliderAngle igSliderAngle;
            pImGuiTableColumnSortSpecs_destroy ImGuiTableColumnSortSpecs_destroy;
            pigSetWindowPos_Vec2 igSetWindowPos_Vec2;
            pigSetWindowPos_Str igSetWindowPos_Str;
            pigSetWindowPos_WindowPtr igSetWindowPos_WindowPtr;
            pigTempInputText igTempInputText;
            pigSetScrollHereY igSetScrollHereY;
            pImGuiViewport_ImGuiViewport ImGuiViewport_ImGuiViewport;
            pigProgressBar igProgressBar;
            pImDrawList_CloneOutput ImDrawList_CloneOutput;
            pImFontGlyphRangesBuilder_destroy ImFontGlyphRangesBuilder_destroy;
            pImVec1_destroy ImVec1_destroy;
            pigPushColumnClipRect igPushColumnClipRect;
            pigLogTextV igLogTextV;
            pigImTextCharFromUtf8 igImTextCharFromUtf8;
            pImRect_ImRect_Nil ImRect_ImRect_Nil;
            pImRect_ImRect_Vec2 ImRect_ImRect_Vec2;
            pImRect_ImRect_Vec4 ImRect_ImRect_Vec4;
            pImRect_ImRect_Float ImRect_ImRect_Float;
            pigGetTopMostPopupModal igGetTopMostPopupModal;
            pImDrawListSplitter_Split ImDrawListSplitter_Split;
            pigBulletText igBulletText;
            pigImFontAtlasBuildFinish igImFontAtlasBuildFinish;
            pigDebugNodeViewport igDebugNodeViewport;
            pImDrawList_AddQuad ImDrawList_AddQuad;
            pigIsItemDeactivated igIsItemDeactivated;
            pigGetColorU32_Col igGetColorU32_Col;
            pigGetColorU32_Vec4 igGetColorU32_Vec4;
            pigGetColorU32_U32 igGetColorU32_U32;
            pImGuiWindow_GetIDFromRectangle ImGuiWindow_GetIDFromRectangle;
            pImDrawList_AddDrawCmd ImDrawList_AddDrawCmd;
            pigUpdateWindowParentAndRootLinks igUpdateWindowParentAndRootLinks;
            pigSetCursorPosX igSetCursorPosX;
            pigInputFloat4 igInputFloat4;
            pigSeparator igSeparator;
            pImRect_Translate ImRect_Translate;
            pImDrawList_PrimUnreserve ImDrawList_PrimUnreserve;
            pigColorPickerOptionsPopup igColorPickerOptionsPopup;
            pImRect_IsInverted ImRect_IsInverted;
            pigGetKeyIndex igGetKeyIndex;
            pImGuiMetricsConfig_destroy ImGuiMetricsConfig_destroy;
            pigPushItemFlag igPushItemFlag;
            pigScrollbar igScrollbar;
            pigDebugNodeWindowsList igDebugNodeWindowsList;
            pImDrawList_PrimWriteVtx ImDrawList_PrimWriteVtx;
            pigSetActiveID igSetActiveID;
            pImGuiPayload_IsDataType ImGuiPayload_IsDataType;
            pigSetWindowSize_Vec2 igSetWindowSize_Vec2;
            pigSetWindowSize_Str igSetWindowSize_Str;
            pigSetWindowSize_WindowPtr igSetWindowSize_WindowPtr;
            pImFontGlyphRangesBuilder_BuildRanges ImFontGlyphRangesBuilder_BuildRanges;
            pigTreePop igTreePop;
            pigTableGetCellBgRect igTableGetCellBgRect;
            pImFont_AddRemapChar ImFont_AddRemapChar;
            pigNavMoveRequestCancel igNavMoveRequestCancel;
            pigText igText;
            pigCollapseButton igCollapseButton;
            pImGuiWindow_TitleBarRect ImGuiWindow_TitleBarRect;
            pigIsItemFocused igIsItemFocused;
            pigMemAlloc igMemAlloc;
            pImGuiStackSizes_destroy ImGuiStackSizes_destroy;
            pigColorPicker3 igColorPicker3;
            pImGuiTextBuffer_destroy ImGuiTextBuffer_destroy;
            pigGetColumnOffset igGetColumnOffset;
            pImRect_GetSize ImRect_GetSize;
            pigSetItemUsingMouseWheel igSetItemUsingMouseWheel;
            pigIsWindowCollapsed igIsWindowCollapsed;
            pImGuiNextItemData_ClearFlags ImGuiNextItemData_ClearFlags;
            pigBeginCombo igBeginCombo;
            pImRect_Expand_Float ImRect_Expand_Float;
            pImRect_Expand_Vec2 ImRect_Expand_Vec2;
            pigOpenPopup igOpenPopup;
            pigImCharIsBlankW igImCharIsBlankW;
            pImFont_SetGlyphVisible ImFont_SetGlyphVisible;
            pigFindOrCreateWindowSettings igFindOrCreateWindowSettings;
            pigInputScalarN igInputScalarN;
            pImDrawList_PrimQuadUV ImDrawList_PrimQuadUV;
            pigPopID igPopID;
            pigEndTabBar igEndTabBar;
            pigPopAllowKeyboardFocus igPopAllowKeyboardFocus;
            pImDrawList_AddImage ImDrawList_AddImage;
            pigBeginTabBar igBeginTabBar;
            pigGetCursorPosY igGetCursorPosY;
            pigCalcTextSize igCalcTextSize;
            pImFont_CalcTextSizeA ImFont_CalcTextSizeA;
            pigImClamp igImClamp;
            pigGetColumnWidth igGetColumnWidth;
            pigTableHeader igTableHeader;
            pImGuiPayload_Clear ImGuiPayload_Clear;
            pImGuiTextBuffer_reserve ImGuiTextBuffer_reserve;
            pImGuiInputTextState_CursorAnimReset ImGuiInputTextState_CursorAnimReset;
            pImRect_ClipWithFull ImRect_ClipWithFull;
            pigGetFontTexUvWhitePixel igGetFontTexUvWhitePixel;
            pImDrawList_ChannelsSplit ImDrawList_ChannelsSplit;
            pigCalcWindowNextAutoFitSize igCalcWindowNextAutoFitSize;
            pigPopFont igPopFont;
            pigImTriangleContainsPoint igImTriangleContainsPoint;
            pigRenderRectFilledWithHole igRenderRectFilledWithHole;
            pigImFloor_Float igImFloor_Float;
            pigImFloor_Vec2 igImFloor_Vec2;
            pImDrawList_AddRect ImDrawList_AddRect;
            pigImParseFormatFindEnd igImParseFormatFindEnd;
            pImGuiTableColumnSettings_destroy ImGuiTableColumnSettings_destroy;
            pImGuiInputTextCallbackData_ClearSelection ImGuiInputTextCallbackData_ClearSelection;
            pigErrorCheckEndFrameRecover igErrorCheckEndFrameRecover;
            pImGuiTextRange_split ImGuiTextRange_split;
            pImBitVector_Clear ImBitVector_Clear;
            pigCreateNewWindowSettings igCreateNewWindowSettings;
            pigGetDrawListSharedData igGetDrawListSharedData;
            pigImFileClose igImFileClose;
            pigBeginChildEx igBeginChildEx;
            pImGuiNextWindowData_ClearFlags ImGuiNextWindowData_ClearFlags;
            pImFontGlyphRangesBuilder_GetBit ImFontGlyphRangesBuilder_GetBit;
            pigImRotate igImRotate;
            pigImGetDirQuadrantFromDelta igImGetDirQuadrantFromDelta;
            pigTableMergeDrawChannels igTableMergeDrawChannels;
            pImFontAtlas_AddFont ImFontAtlas_AddFont;
            pigGetNavInputAmount2d igGetNavInputAmount2d;
        }
    }
    extern (C) @nogc nothrow {
        version (USE_GLFW) {
            import bindbc.sdl;

            alias pImGui_ImplGlfw_NewFrame = void function();
            alias pImGui_ImplGlfw_InitForOther = bool function(GLFWwindow* window, bool install_callbacks);
            alias pImGui_ImplGlfw_InitForVulkan = bool function(GLFWwindow* window, bool install_callbacks);
            alias pImGui_ImplGlfw_CharCallback = void function(GLFWwindow* window, uint c);
            alias pImGui_ImplGlfw_InitForOpenGL = bool function(GLFWwindow* window, bool install_callbacks);
            alias pImGui_ImplGlfw_KeyCallback = void function(GLFWwindow* window, int key, int scancode, int action, int mods);
            alias pImGui_ImplGlfw_ScrollCallback = void function(GLFWwindow* window, double xoffset, double yoffset);
            alias pImGui_ImplGlfw_MouseButtonCallback = void function(GLFWwindow* window, int button, int action, int mods);
            alias pImGui_ImplGlfw_Shutdown = void function();

            __gshared {
                pImGui_ImplGlfw_NewFrame ImGui_ImplGlfw_NewFrame;
                pImGui_ImplGlfw_InitForOther ImGui_ImplGlfw_InitForOther;
                pImGui_ImplGlfw_InitForVulkan ImGui_ImplGlfw_InitForVulkan;
                pImGui_ImplGlfw_CharCallback ImGui_ImplGlfw_CharCallback;
                pImGui_ImplGlfw_InitForOpenGL ImGui_ImplGlfw_InitForOpenGL;
                pImGui_ImplGlfw_KeyCallback ImGui_ImplGlfw_KeyCallback;
                pImGui_ImplGlfw_ScrollCallback ImGui_ImplGlfw_ScrollCallback;
                pImGui_ImplGlfw_MouseButtonCallback ImGui_ImplGlfw_MouseButtonCallback;
                pImGui_ImplGlfw_Shutdown ImGui_ImplGlfw_Shutdown;
            }
        }
        version (USE_OpenGL3) {

            alias pImGui_ImplOpenGL3_DestroyFontsTexture = void function();
            alias pImGui_ImplOpenGL3_CreateFontsTexture = bool function();
            alias pImGui_ImplOpenGL3_CreateDeviceObjects = bool function();
            alias pImGui_ImplOpenGL3_Init = bool function(const(char)* glsl_version);
            alias pImGui_ImplOpenGL3_DestroyDeviceObjects = void function();
            alias pImGui_ImplOpenGL3_NewFrame = void function();
            alias pImGui_ImplOpenGL3_Shutdown = void function();
            alias pImGui_ImplOpenGL3_RenderDrawData = void function(ImDrawData* draw_data);

            __gshared {
                pImGui_ImplOpenGL3_DestroyFontsTexture ImGui_ImplOpenGL3_DestroyFontsTexture;
                pImGui_ImplOpenGL3_CreateFontsTexture ImGui_ImplOpenGL3_CreateFontsTexture;
                pImGui_ImplOpenGL3_CreateDeviceObjects ImGui_ImplOpenGL3_CreateDeviceObjects;
                pImGui_ImplOpenGL3_Init ImGui_ImplOpenGL3_Init;
                pImGui_ImplOpenGL3_DestroyDeviceObjects ImGui_ImplOpenGL3_DestroyDeviceObjects;
                pImGui_ImplOpenGL3_NewFrame ImGui_ImplOpenGL3_NewFrame;
                pImGui_ImplOpenGL3_Shutdown ImGui_ImplOpenGL3_Shutdown;
                pImGui_ImplOpenGL3_RenderDrawData ImGui_ImplOpenGL3_RenderDrawData;
            }
        }
        version (USE_SDL2) {
            import bindbc.sdl;

            alias pImGui_ImplSDL2_Shutdown = void function();
            alias pImGui_ImplSDL2_InitForMetal = bool function(SDL_Window* window);
            alias pImGui_ImplSDL2_InitForOpenGL = bool function(SDL_Window* window, void* sdl_gl_context);
            alias pImGui_ImplSDL2_InitForVulkan = bool function(SDL_Window* window);
            alias pImGui_ImplSDL2_InitForD3D = bool function(SDL_Window* window);
            alias pImGui_ImplSDL2_ProcessEvent = bool function(const SDL_Event* event);
            alias pImGui_ImplSDL2_NewFrame = void function(SDL_Window* window);

            __gshared {
                pImGui_ImplSDL2_Shutdown ImGui_ImplSDL2_Shutdown;
                pImGui_ImplSDL2_InitForMetal ImGui_ImplSDL2_InitForMetal;
                pImGui_ImplSDL2_InitForOpenGL ImGui_ImplSDL2_InitForOpenGL;
                pImGui_ImplSDL2_InitForVulkan ImGui_ImplSDL2_InitForVulkan;
                pImGui_ImplSDL2_InitForD3D ImGui_ImplSDL2_InitForD3D;
                pImGui_ImplSDL2_ProcessEvent ImGui_ImplSDL2_ProcessEvent;
                pImGui_ImplSDL2_NewFrame ImGui_ImplSDL2_NewFrame;
            }
        }
        version (USE_OpenGL2) {

            alias pImGui_ImplOpenGL2_CreateDeviceObjects = bool function();
            alias pImGui_ImplOpenGL2_Init = bool function();
            alias pImGui_ImplOpenGL2_DestroyDeviceObjects = void function();
            alias pImGui_ImplOpenGL2_NewFrame = void function();
            alias pImGui_ImplOpenGL2_RenderDrawData = void function(ImDrawData* draw_data);
            alias pImGui_ImplOpenGL2_CreateFontsTexture = bool function();
            alias pImGui_ImplOpenGL2_Shutdown = void function();
            alias pImGui_ImplOpenGL2_DestroyFontsTexture = void function();

            __gshared {
                pImGui_ImplOpenGL2_CreateDeviceObjects ImGui_ImplOpenGL2_CreateDeviceObjects;
                pImGui_ImplOpenGL2_Init ImGui_ImplOpenGL2_Init;
                pImGui_ImplOpenGL2_DestroyDeviceObjects ImGui_ImplOpenGL2_DestroyDeviceObjects;
                pImGui_ImplOpenGL2_NewFrame ImGui_ImplOpenGL2_NewFrame;
                pImGui_ImplOpenGL2_RenderDrawData ImGui_ImplOpenGL2_RenderDrawData;
                pImGui_ImplOpenGL2_CreateFontsTexture ImGui_ImplOpenGL2_CreateFontsTexture;
                pImGui_ImplOpenGL2_Shutdown ImGui_ImplOpenGL2_Shutdown;
                pImGui_ImplOpenGL2_DestroyFontsTexture ImGui_ImplOpenGL2_DestroyFontsTexture;
            }
        }
    }
}
