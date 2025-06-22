module i2d.imgui.bind.imgui;

import std.algorithm;

import std.traits;

import core.stdc.stdio;

import core.stdc.stdarg;

import core.stdc.string;

extern (C) {
    
    alias stbrp_coord = int;
    struct stbrp_node
    {
       stbrp_coord  x,y;
       stbrp_node  *next;
    };
    alias ImFontAtlasRectId = int;
    alias ImS16 = short;
    alias ImU32 = uint;
    alias ImGuiSizeCallback = void     function(ImGuiSizeCallbackData* data);
    alias ImGuiContextHookCallback = void  function(ImGuiContext* ctx, ImGuiContextHook* hook);
    alias ImS8 = byte;
    alias ImU64 = ulong;
    alias ImGuiID = uint;
    alias ImGuiTableDrawChannelIdx = ImU16;
    alias ImWchar = ImWchar32;
    alias ImGuiInputTextCallback = int      function(ImGuiInputTextCallbackData* data);
    alias ImDrawIdx = ushort;
    alias ImPoolIdx = int;
    alias ImDrawCallback = void  function(const ImDrawList* parent_list, const ImDrawCmd* cmd);
    alias ImS32 = int;
    alias ImGuiKeyChord = int;
    alias ImGuiMemFreeFunc = void     function(void* ptr, void* user_data);
    alias ImGuiSelectionUserData = ImS64;
    struct ImGuiTableColumnsSettings;
    struct STB_TexteditState;
    alias ImU16 = ushort;
    alias ImWchar16 = ushort;
    alias ImWchar32 = uint;
    alias ImS64 = long;
    alias ImFileHandle = FILE*;
    alias ImU8 = char;
    alias ImGuiKeyRoutingIndex = ImS16;
    alias ImGuiTableColumnIdx = ImS16;
    alias ImTextureID = ImU64;
    struct ImGuiInputTextDeactivateData;
    struct ImStbTexteditState;
    alias ImGuiErrorCallback = void  function(ImGuiContext* ctx, void* user_data, const(char)* msg);
    alias ImBitArrayForNamedKeys = ImBitArray!(ImGuiKey.NamedKey_COUNT,-ImGuiKey.NamedKey_BEGIN);
    alias ImBitArrayPtr = ImU32*;
    alias ImGuiMemAllocFunc = void*    function(size_t sz, void* user_data);
    alias stbrp_node_im = stbrp_node;
    
    size_t imMemAlign(size_t size, size_t alignment)
    {
        return (size + alignment - 1) & ~(alignment - 1);
    }
    
    struct ImStableVector(tType, size_t BLOCK_SIZE) {
        int Size;
        int Capacity;
        ImVector!(tType*) Blocks;
    
        ~this()
        {
            for (int n = 0; n < Capacity; n++)
            {
                igMemFree(Blocks[n]);
            }
        }
    
        void clear()
        {
            Size = 0;
            Capacity = 0;
            Blocks.clear_delete();
        }
    
        void resize(int new_size)
        { 
            if (new_size > Capacity) 
            {
                reserve(cast(int)new_size); 
                Size = new_size; 
            }
        }
    
        void reserve(int new_cap)
        {
            new_cap = cast(int)imMemAlign(new_cap, cast(size_t)BLOCK_SIZE);
            int old_count = cast(int)(Capacity / BLOCK_SIZE);
            int new_count = cast(int)(new_cap / BLOCK_SIZE);
            if (new_count <= old_count)
            {
                return;
            }
    
            Blocks.resize(new_count);
            for (int n = old_count; n < new_count; n++)
            {
                Blocks[n] = cast(tType*)igMemAlloc(tType.sizeof * BLOCK_SIZE);
            }
            Capacity = new_cap;
        }
        
        ref auto opIndex(size_t index)
        {
            return Blocks[index / BLOCK_SIZE][index % BLOCK_SIZE];
        }
    
        ref auto push_back(const(tType) v) 
        {
            int i = Size;
            assert(i >= 0);
            if (Size == Capacity)
            {
                reserve(cast(int)(Capacity + BLOCK_SIZE));
            }  
            
            void* ptr = &Blocks[i / BLOCK_SIZE][i % BLOCK_SIZE]; 
            memcpy(ptr, &v, v.sizeof); 
            Size++; 
            return cast(tType*)ptr;        
        }
    }
    
    struct ImVector(tType) {
        int Size;
        int Capacity;
        tType* Data;
    
        import core.stdc.string;
    
        // Important: never called automatically! always explicit.
        void clear_delete()() if (isPointer!(tType))
        { 
            for (int n = 0; n < Size; n++) {
                destroy(Data[n]); 
                igMemFree(cast(void*)Data[n]);
            }
                
            clear();
        }
    
        // Important: never called automatically! always explicit.
        void clear_destruct()
        { 
            for (int n = 0; n < Size; n++) 
            {
                destroy(Data[n]);
            }
    
            clear(); 
        }
    
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
    
        ref auto opIndex(size_t index)
        {
            return Data[index];
        }
    
        // NB: It is illegal to call push_back/push_front/insert with a reference pointing inside the 
        // ImVector data itself! e.g. v.push_back(v[10]) is forbidden.
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
    
    struct ImBitArray(int BITCOUNT, int OFFSET = 0)
    {
        ImU32[(BITCOUNT + 31) >> 5] Storage;
        //ImBitArray()
        //{ 
        //    ClearAllBits(); 
        //}
    
        void ClearAllBits()
        { 
            core.stdc.string.memset(Storage.ptr, 0, Storage.sizeof);
        }
    
        void SetAllBits()
        { 
            core.stdc.string.memset(Storage.ptr, 255, Storage.sizeof);
        }
    
        bool TestBit(int n) const
        { 
            n += OFFSET; 
            assert(n >= 0 && n < BITCOUNT); 
            return igImBitArrayTestBit(Storage.ptr, n); 
        }
    
        void SetBit(int n)
        { 
            n += OFFSET;
            assert(n >= 0 && n < BITCOUNT); 
            igImBitArraySetBit(Storage.ptr, n); 
        }
    
        void ClearBit(int n)
        { 
            n += OFFSET;
            assert(n >= 0 && n < BITCOUNT); 
            igImBitArrayClearBit(Storage.ptr, n); 
        }
        
        // Works on range [n..n2)
        void SetBitRange(int n, int n2)
        { 
            n += OFFSET; 
            n2 += OFFSET; 
            assert(n >= 0 && n < BITCOUNT && n2 > n && n2 <= BITCOUNT); 
            igImBitArraySetBitRange(Storage.ptr, n, n2); 
        }
    
        bool opIndex(int n) const
        { 
            n += OFFSET; 
            assert(n >= 0 && n < BITCOUNT); 
            return igImBitArrayTestBit(Storage.ptr, n); 
        }
    }
    
    struct ImPool_ImGuiTabBar {
        ImGuiTabBar Buf;
        ImGuiStorage Map;
        ImPoolIdx FreeIdx;
    }
    
    struct ImPool_ImGuiMultiSelectState {
        ImGuiMultiSelectState Buf;
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

    /// Flags for internal's BeginColumns(). This is an obsolete API. Prefer using BeginTable() nowadays!
    enum ImGuiOldColumnFlags {
        None = 0,
        NoBorder = 1, /// Disable column dividers
        NoResize = 2, /// Disable resizing columns when clicking on the dividers
        NoPreserveWidths = 4, /// Disable column width preservation when adjusting columns
        NoForceWithinWindow = 8, /// Disable forcing columns to fit within window
        GrowParentContentsSize = 16, /// Restore pre-1.51 behavior of extending the parent window contents size but _without affecting the columns width at all_. Will eventually remove.
    }

    /// FIXME: this is in development, not exposed/functional as a generic feature yet.
    /// Horizontal/Vertical enums are fixed to 0/1 so they may be used to index ImVec2
    enum ImGuiLayoutType {
        Horizontal = 0,
        Vertical = 1,
    }

    /// Enum for ImGui::TableSetBgColor()
    /// Background colors are rendering in 3 layers:
    ///  - Layer 0: draw with RowBg0 color if set, otherwise draw with ColumnBg0 if set.
    ///  - Layer 1: draw with RowBg1 color if set, otherwise draw with ColumnBg1 if set.
    ///  - Layer 2: draw with CellBg color if set.
    /// The purpose of the two row/columns layers is to let you decide if a background color change should override or blend with the existing color.
    /// When using ImGuiTableFlags_RowBg on the table, each row has the RowBg0 color automatically set for odd/even rows.
    /// If you set the color of RowBg0 target, your color will override the existing RowBg0 color.
    /// If you set the color of RowBg1 or ColumnBg1 target, your color will blend over the RowBg0 color.
    enum ImGuiTableBgTarget {
        None = 0,
        RowBg0 = 1, /// Set row background color 0 (generally used for background, automatically set when ImGuiTableFlags_RowBg is used)
        RowBg1 = 2, /// Set row background color 1 (generally used for selection marking)
        CellBg = 3, /// Set cell background color (top-most color)
    }

    enum ImGuiSeparatorFlags {
        None = 0,
        Horizontal = 1, /// Axis default to current layout type, so generally Horizontal unless e.g. in a menu bar
        Vertical = 2,
        SpanAllColumns = 4, /// Make separator cover all columns of a legacy Columns() set.
    }

    /// List of colors that are stored at the time of Begin() into Docked Windows.
    /// We currently store the packed colors in a simple array window->DockStyle.Colors[].
    /// A better solution may involve appending into a log of colors in ImGuiContext + store offsets into those arrays in ImGuiWindow,
    /// but it would be more complex as we'd need to double-buffer both as e.g. drop target may refer to window from last frame.
    enum ImGuiWindowDockStyleCol {
        Text = 0,
        TabHovered = 1,
        TabFocused = 2,
        TabSelected = 3,
        TabSelectedOverline = 4,
        TabDimmed = 5,
        TabDimmedSelected = 6,
        TabDimmedSelectedOverline = 7,
        COUNT = 8,
    }

    enum ImGuiNavRenderCursorFlags {
        None = 0,
        Compact = 2, /// Compact highlight, no padding/distance from focused item
        AlwaysDraw = 4, /// Draw rectangular highlight if (g.NavId == id) even when g.NavCursorVisible == false, aka even when using the mouse.
        NoRounding = 8,
    }

    enum ImGuiNextItemDataFlags {
        None = 0,
        HasWidth = 1,
        HasOpen = 2,
        HasShortcut = 4,
        HasRefVal = 8,
        HasStorageID = 16,
    }

    /// Flags for FocusWindow(). This is not called ImGuiFocusFlags to avoid confusion with public-facing ImGuiFocusedFlags.
    /// FIXME: Once we finishing replacing more uses of GetTopMostPopupModal()+IsWindowWithinBeginStackOf()
    /// and FindBlockingModal() with this, we may want to change the flag to be opt-out instead of opt-in.
    enum ImGuiFocusRequestFlags {
        None = 0,
        RestoreFocusedChild = 1, /// Find last focused child (if any) and focus it instead.
        UnlessBelowModal = 2, /// Do not set focus if the window is below a modal.
    }

    /// Status flags for an already submitted item
    /// - output: stored in g.LastItemData.StatusFlags
    enum ImGuiItemStatusFlags {
        None = 0,
        HoveredRect = 1, /// Mouse position is within item rectangle (does NOT mean that the window is in correct z-order and can be hovered!, this is only one part of the most-common IsItemHovered test)
        HasDisplayRect = 2, /// g.LastItemData.DisplayRect is valid
        Edited = 4, /// Value exposed by item was edited in the current frame (should match the bool return value of most widgets)
        ToggledSelection = 8, /// Set when Selectable(), TreeNode() reports toggling a selection. We can't report "Selected", only state changes, in order to easily handle clipping with less issues.
        ToggledOpen = 16, /// Set when TreeNode() reports toggling their open state.
        HasDeactivated = 32, /// Set if the widget/group is able to provide data for the ImGuiItemStatusFlags_Deactivated flag.
        Deactivated = 64, /// Only valid if ImGuiItemStatusFlags_HasDeactivated is set.
        HoveredWindow = 128, /// Override the HoveredWindow test to allow cross-window hover testing.
        Visible = 256, /// [WIP] Set when item is overlapping the current clipping rectangle (Used internally. Please don't use yet: API/system will change as we refactor Itemadd()).
        HasClipRect = 512, /// g.LastItemData.ClipRect is valid.
        HasShortcut = 1024, /// g.LastItemData.Shortcut valid. Set by SetNextItemShortcut() -> ItemAdd().
    }

    /// Extend ImGuiHoveredFlags_
    enum ImGuiHoveredFlagsI : ImGuiHoveredFlags {
        DelayMask_ = cast(ImGuiHoveredFlags)245760,
        AllowedMaskForIsWindowHovered = cast(ImGuiHoveredFlags)12479,
        AllowedMaskForIsItemHovered = cast(ImGuiHoveredFlags)262048,
    }

    /// Extend ImGuiSliderFlags_
    enum ImGuiSliderFlagsI : ImGuiSliderFlags {
        Vertical = cast(ImGuiSliderFlags)1048576, /// Should this slider be orientated vertically?
        ReadOnly = cast(ImGuiSliderFlags)2097152, /// Consider using g.NextItemData.ItemFlags |= ImGuiItemFlags_ReadOnly instead.
    }

    /// Identify a mouse button.
    /// Those values are guaranteed to be stable and we frequently use 0/1 directly. Named enums provided for convenience.
    enum ImGuiMouseButton {
        Left = 0,
        Right = 1,
        Middle = 2,
        COUNT = 5,
    }

    /// Enumeration for AddMouseSourceEvent() actual source of Mouse Input data.
    /// Historically we use "Mouse" terminology everywhere to indicate pointer data, e.g. MousePos, IsMousePressed(), io.AddMousePosEvent()
    /// But that "Mouse" data can come from different source which occasionally may be useful for application to know about.
    /// You can submit a change of pointer type using io.AddMouseSourceEvent().
    enum ImGuiMouseSource {
        Mouse = 0, /// Input is coming from an actual mouse.
        TouchScreen = 1, /// Input is coming from a touch screen (no hovering prior to initial press, less precise initial press aiming, dual-axis wheeling possible).
        Pen = 2, /// Input is coming from a pressure/magnetic pen (often used in conjunction with high-sampling rates).
        COUNT = 3,
    }

    /// Flags for GetTypingSelectRequest()
    enum ImGuiTypingSelectFlags {
        None = 0,
        AllowBackspace = 1, /// Backspace to delete character inputs. If using: ensure GetTypingSelectRequest() is not called more than once per frame (filter by e.g. focus state)
        AllowSingleCharMode = 2, /// Allow "single char" search mode which is activated when pressing the same character multiple times.
    }

    /// Extend ImGuiDockNodeFlags_
    enum ImGuiDockNodeFlagsI : ImGuiDockNodeFlags {
        DockSpace = cast(ImGuiDockNodeFlags)1024, /// Saved /// A dockspace is a node that occupy space within an existing user window. Otherwise the node is floating and create its own window.
        CentralNode = cast(ImGuiDockNodeFlags)2048, /// Saved /// The central node has 2 main properties: stay visible when empty, only use "remaining" spaces from its neighbor.
        NoTabBar = cast(ImGuiDockNodeFlags)4096, /// Saved /// Tab bar is completely unavailable. No triangle in the corner to enable it back.
        HiddenTabBar = cast(ImGuiDockNodeFlags)8192, /// Saved /// Tab bar is hidden, with a triangle in the corner to show it again (NB: actual tab-bar instance may be destroyed as this is only used for single-window tab bar)
        NoWindowMenuButton = cast(ImGuiDockNodeFlags)16384, /// Saved /// Disable window/docking menu (that one that appears instead of the collapse button)
        NoCloseButton = cast(ImGuiDockNodeFlags)32768, /// Saved /// Disable close button
        NoResizeX = cast(ImGuiDockNodeFlags)65536, ///       //
        NoResizeY = cast(ImGuiDockNodeFlags)131072, ///       //
        DockedWindowsInFocusRoute = cast(ImGuiDockNodeFlags)262144, ///       /// Any docked window will be automatically be focus-route chained (window->ParentWindowForFocusRoute set to this) so Shortcut() in this window can run when any docked window is focused.
        NoDockingSplitOther = cast(ImGuiDockNodeFlags)524288, ///       /// Disable this node from splitting other windows/nodes.
        NoDockingOverMe = cast(ImGuiDockNodeFlags)1048576, ///       /// Disable other windows/nodes from being docked over this node.
        NoDockingOverOther = cast(ImGuiDockNodeFlags)2097152, ///       /// Disable this node from being docked over another window or non-empty node.
        NoDockingOverEmpty = cast(ImGuiDockNodeFlags)4194304, ///       /// Disable this node from being docked over an empty node (e.g. DockSpace with no other windows)
        NoDocking = cast(ImGuiDockNodeFlags)7864336,
        SharedFlagsInheritMask_ = cast(ImGuiDockNodeFlags)-1,
        NoResizeFlagsMask_ = cast(ImGuiDockNodeFlags)196640,
        LocalFlagsTransferMask_ = cast(ImGuiDockNodeFlags)260208,
        SavedFlagsMask_ = cast(ImGuiDockNodeFlags)261152,
    }

    /// Store the source authority (dock node vs window) of a field
    enum ImGuiDataAuthority {
        Auto = 0,
        DockNode = 1,
        Window = 2,
    }

    enum ImGuiInputEventType {
        None = 0,
        MousePos = 1,
        MouseWheel = 2,
        MouseButton = 3,
        MouseViewport = 4,
        Key = 5,
        Text = 6,
        Focus = 7,
        COUNT = 8,
    }

    /// Extend ImGuiInputFlags_
    /// Flags for extended versions of IsKeyPressed(), IsMouseClicked(), Shortcut(), SetKeyOwner(), SetItemKeyOwner()
    /// Don't mistake with ImGuiInputTextFlags! (which is for ImGui::InputText() function)
    enum ImGuiInputFlagsI : ImGuiInputFlags {
        RepeatRateDefault = cast(ImGuiInputFlags)2, /// Repeat rate: Regular (default)
        RepeatRateNavMove = cast(ImGuiInputFlags)4, /// Repeat rate: Fast
        RepeatRateNavTweak = cast(ImGuiInputFlags)8, /// Repeat rate: Faster
        RepeatUntilRelease = cast(ImGuiInputFlags)16, /// Stop repeating when released (default for all functions except Shortcut). This only exists to allow overriding Shortcut() default behavior.
        RepeatUntilKeyModsChange = cast(ImGuiInputFlags)32, /// Stop repeating when released OR if keyboard mods are changed (default for Shortcut)
        RepeatUntilKeyModsChangeFromNone = cast(ImGuiInputFlags)64, /// Stop repeating when released OR if keyboard mods are leaving the None state. Allows going from Mod+Key to Key by releasing Mod.
        RepeatUntilOtherKeyPress = cast(ImGuiInputFlags)128, /// Stop repeating when released OR if any other keyboard key is pressed during the repeat
        LockThisFrame = cast(ImGuiInputFlags)1048576, /// Further accesses to key data will require EXPLICIT owner ID (ImGuiKeyOwner_Any/0 will NOT accepted for polling). Cleared at end of frame.
        LockUntilRelease = cast(ImGuiInputFlags)2097152, /// Further accesses to key data will require EXPLICIT owner ID (ImGuiKeyOwner_Any/0 will NOT accepted for polling). Cleared when the key is released or at end of each frame if key is released.
        CondHovered = cast(ImGuiInputFlags)4194304, /// Only set if item is hovered (default to both)
        CondActive = cast(ImGuiInputFlags)8388608, /// Only set if item is active (default to both)
        CondDefault_ = cast(ImGuiInputFlags)12582912,
        RepeatRateMask_ = cast(ImGuiInputFlags)14,
        RepeatUntilMask_ = cast(ImGuiInputFlags)240,
        RepeatMask_ = cast(ImGuiInputFlags)255,
        CondMask_ = cast(ImGuiInputFlags)12582912,
        RouteTypeMask_ = cast(ImGuiInputFlags)15360,
        RouteOptionsMask_ = cast(ImGuiInputFlags)245760,
        SupportedByIsKeyPressed = cast(ImGuiInputFlags)255,
        SupportedByIsMouseClicked = cast(ImGuiInputFlags)1,
        SupportedByShortcut = cast(ImGuiInputFlags)261375,
        SupportedBySetNextItemShortcut = cast(ImGuiInputFlags)523519,
        SupportedBySetKeyOwner = cast(ImGuiInputFlags)3145728,
        SupportedBySetItemKeyOwner = cast(ImGuiInputFlags)15728640,
    }

    enum ImGuiPlotType {
        Lines = 0,
        Histogram = 1,
    }

    /// Extend ImGuiTabBarFlags_
    enum ImGuiTabBarFlagsI : ImGuiTabBarFlags {
        DockNode = cast(ImGuiTabBarFlags)1048576, /// Part of a dock node [we don't use this in the master branch but it facilitate branch syncing to keep this around]
        IsFocused = cast(ImGuiTabBarFlags)2097152,
        SaveSettings = cast(ImGuiTabBarFlags)4194304, /// FIXME: Settings are handled by the docking system, this only request the tab bar to mark settings dirty when reordering tabs
    }

    /// Flags for ImGui::TableSetupColumn()
    enum ImGuiTableColumnFlags {
        None = 0,
        Disabled = 1, /// Overriding/master disable flag: hide column, won't show in context menu (unlike calling TableSetColumnEnabled() which manipulates the user accessible state)
        DefaultHide = 2, /// Default as a hidden/disabled column.
        DefaultSort = 4, /// Default as a sorting column.
        WidthStretch = 8, /// Column will stretch. Preferable with horizontal scrolling disabled (default if table sizing policy is _SizingStretchSame or _SizingStretchProp).
        WidthFixed = 16, /// Column will not stretch. Preferable with horizontal scrolling enabled (default if table sizing policy is _SizingFixedFit and table is resizable).
        NoResize = 32, /// Disable manual resizing.
        NoReorder = 64, /// Disable manual reordering this column, this will also prevent other columns from crossing over this column.
        NoHide = 128, /// Disable ability to hide/disable this column.
        NoClip = 256, /// Disable clipping for this column (all NoClip columns will render in a same draw command).
        NoSort = 512, /// Disable ability to sort on this field (even if ImGuiTableFlags_Sortable is set on the table).
        NoSortAscending = 1024, /// Disable ability to sort in the ascending direction.
        NoSortDescending = 2048, /// Disable ability to sort in the descending direction.
        NoHeaderLabel = 4096, /// TableHeadersRow() will submit an empty label for this column. Convenient for some small columns. Name will still appear in context menu or in angled headers. You may append into this cell by calling TableSetColumnIndex() right after the TableHeadersRow() call.
        NoHeaderWidth = 8192, /// Disable header text width contribution to automatic column width.
        PreferSortAscending = 16384, /// Make the initial sort direction Ascending when first sorting on this column (default).
        PreferSortDescending = 32768, /// Make the initial sort direction Descending when first sorting on this column.
        IndentEnable = 65536, /// Use current Indent value when entering cell (default for column 0).
        IndentDisable = 131072, /// Ignore current Indent value when entering cell (default for columns > 0). Indentation changes _within_ the cell will still be honored.
        AngledHeader = 262144, /// TableHeadersRow() will submit an angled header row for this column. Note this will add an extra row.
        IsEnabled = 16777216, /// Status: is enabled == not hidden by user/api (referred to as "Hide" in _DefaultHide and _NoHide) flags.
        IsVisible = 33554432, /// Status: is visible == is enabled AND not clipped by scrolling.
        IsSorted = 67108864, /// Status: is currently part of the sort specs
        IsHovered = 134217728, /// Status: is hovered by mouse
        WidthMask_ = 24,
        IndentMask_ = 196608,
        StatusMask_ = 251658240,
        NoDirectResize_ = 1073741824, /// [Internal] Disable user resizing this column directly (it may however we resized indirectly from its left edge)
    }

    enum ImGuiTooltipFlags {
        None = 0,
        OverridePrevious = 2, /// Clear/ignore previously submitted tooltip (defaults to append)
    }

    /// Flags for ImGui::BeginTabItem()
    enum ImGuiTabItemFlags {
        None = 0,
        UnsavedDocument = 1, /// Display a dot next to the title + set ImGuiTabItemFlags_NoAssumedClosure.
        SetSelected = 2, /// Trigger flag to programmatically make the tab selected when calling BeginTabItem()
        NoCloseWithMiddleMouseButton = 4, /// Disable behavior of closing tabs (that are submitted with p_open != NULL) with middle mouse button. You may handle this behavior manually on user's side with if (IsItemHovered() && IsMouseClicked(2)) *p_open = false.
        NoPushId = 8, /// Don't call PushID()/PopID() on BeginTabItem()/EndTabItem()
        NoTooltip = 16, /// Disable tooltip for the given tab
        NoReorder = 32, /// Disable reordering this tab or having another tab cross over this tab
        Leading = 64, /// Enforce the tab position to the left of the tab bar (after the tab list popup button)
        Trailing = 128, /// Enforce the tab position to the right of the tab bar (before the scrolling buttons)
        NoAssumedClosure = 256, /// Tab is selected when trying to close + closure is not immediately assumed (will wait for user to stop submitting the tab). Otherwise closure is assumed when pressing the X, so if you keep submitting the tab may reappear at end of tab bar.
    }

    /// This is experimental and not officially supported, it'll probably fall short of features, if/when it does we may backtrack.
    enum ImGuiLocKey {
        VersionStr = 0,
        TableSizeOne = 1,
        TableSizeAllFit = 2,
        TableSizeAllDefault = 3,
        TableResetOrder = 4,
        WindowingMainMenuBar = 5,
        WindowingPopup = 6,
        WindowingUntitled = 7,
        OpenLink_s = 8,
        CopyLink = 9,
        DockingHideTabBar = 10,
        DockingHoldShiftToDock = 11,
        DockingDragToUndockOrMoveNode = 12,
        COUNT = 13,
    }

    enum ImGuiPopupPositionPolicy {
        Default = 0,
        ComboBox = 1,
        Tooltip = 2,
    }

    /// Configuration flags stored in io.ConfigFlags. Set by user/application.
    enum ImGuiConfigFlags {
        None = 0,
        NavEnableKeyboard = 1, /// Master keyboard navigation enable flag. Enable full Tabbing + directional arrows + space/enter to activate.
        NavEnableGamepad = 2, /// Master gamepad navigation enable flag. Backend also needs to set ImGuiBackendFlags_HasGamepad.
        NoMouse = 16, /// Instruct dear imgui to disable mouse inputs and interactions.
        NoMouseCursorChange = 32, /// Instruct backend to not alter mouse cursor shape and visibility. Use if the backend cursor changes are interfering with yours and you don't want to use SetMouseCursor() to change mouse cursor. You may want to honor requests from imgui by reading GetMouseCursor() yourself instead.
        NoKeyboard = 64, /// Instruct dear imgui to disable keyboard inputs and interactions. This is done by ignoring keyboard events and clearing existing states.
        DockingEnable = 128, /// Docking enable flags.
        ViewportsEnable = 1024, /// Viewport enable flags (require both ImGuiBackendFlags_PlatformHasViewports + ImGuiBackendFlags_RendererHasViewports set by the respective backends)
        IsSRGB = 1048576, /// Application is SRGB-aware.
        IsTouchScreen = 2097152, /// Application is using a touch screen instead of a mouse.
    }

    /// Flags for ImGui::BeginChild()
    /// (Legacy: bit 0 must always correspond to ImGuiChildFlags_Borders to be backward compatible with old API using 'bool border = false'.
    /// About using AutoResizeX/AutoResizeY flags:
    /// - May be combined with SetNextWindowSizeConstraints() to set a min/max size for each axis (see "Demo->Child->Auto-resize with Constraints").
    /// - Size measurement for a given axis is only performed when the child window is within visible boundaries, or is just appearing.
    ///   - This allows BeginChild() to return false when not within boundaries (e.g. when scrolling), which is more optimal. BUT it won't update its auto-size while clipped.
    ///     While not perfect, it is a better default behavior as the always-on performance gain is more valuable than the occasional "resizing after becoming visible again" glitch.
    ///   - You may also use ImGuiChildFlags_AlwaysAutoResize to force an update even when child window is not in view.
    ///     HOWEVER PLEASE UNDERSTAND THAT DOING SO WILL PREVENT BeginChild() FROM EVER RETURNING FALSE, disabling benefits of coarse clipping.
    enum ImGuiChildFlags {
        None = 0,
        Borders = 1, /// Show an outer border and enable WindowPadding. (IMPORTANT: this is always == 1 == true for legacy reason)
        AlwaysUseWindowPadding = 2, /// Pad with style.WindowPadding even if no border are drawn (no padding by default for non-bordered child windows because it makes more sense)
        ResizeX = 4, /// Allow resize from right border (layout direction). Enable .ini saving (unless ImGuiWindowFlags_NoSavedSettings passed to window flags)
        ResizeY = 8, /// Allow resize from bottom border (layout direction). "
        AutoResizeX = 16, /// Enable auto-resizing width. Read "IMPORTANT: Size measurement" details above.
        AutoResizeY = 32, /// Enable auto-resizing height. Read "IMPORTANT: Size measurement" details above.
        AlwaysAutoResize = 64, /// Combined with AutoResizeX/AutoResizeY. Always measure size even when child is hidden, always return true, always disable clipping optimization! NOT RECOMMENDED.
        FrameStyle = 128, /// Style the child window like a framed item: use FrameBg, FrameRounding, FrameBorderSize, FramePadding instead of ChildBg, ChildRounding, ChildBorderSize, WindowPadding.
        NavFlattened = 256, /// [BETA] Share focus scope, allow keyboard/gamepad navigation to cross over parent border to this child or between sibling child windows.
    }

    /// Flags for ImGui::TableNextRow()
    enum ImGuiTableRowFlags {
        None = 0,
        Headers = 1, /// Identify header row (set default background color + width of its contents accounted differently for auto column width)
    }

    /// Extend ImGuiDataType_
    enum ImGuiDataTypeI : ImGuiDataType {
        Pointer = cast(ImGuiDataType)12,
        ID = cast(ImGuiDataType)13,
    }

    /// Flags for ImGui::TreeNodeEx(), ImGui::CollapsingHeader*()
    enum ImGuiTreeNodeFlags {
        None = 0,
        Selected = 1, /// Draw as selected
        Framed = 2, /// Draw frame with background (e.g. for CollapsingHeader)
        AllowOverlap = 4, /// Hit testing to allow subsequent widgets to overlap this one
        NoTreePushOnOpen = 8, /// Don't do a TreePush() when open (e.g. for CollapsingHeader) = no extra indent nor pushing on ID stack
        NoAutoOpenOnLog = 16, /// Don't automatically and temporarily open node when Logging is active (by default logging will automatically open tree nodes)
        DefaultOpen = 32, /// Default node to be open
        OpenOnDoubleClick = 64, /// Open on double-click instead of simple click (default for multi-select unless any _OpenOnXXX behavior is set explicitly). Both behaviors may be combined.
        OpenOnArrow = 128, /// Open when clicking on the arrow part (default for multi-select unless any _OpenOnXXX behavior is set explicitly). Both behaviors may be combined.
        Leaf = 256, /// No collapsing, no arrow (use as a convenience for leaf nodes).
        Bullet = 512, /// Display a bullet instead of arrow. IMPORTANT: node can still be marked open/close if you don't set the _Leaf flag!
        FramePadding = 1024, /// Use FramePadding (even for an unframed text node) to vertically align text baseline to regular widget height. Equivalent to calling AlignTextToFramePadding() before the node.
        SpanAvailWidth = 2048, /// Extend hit box to the right-most edge, even if not framed. This is not the default in order to allow adding other items on the same line without using AllowOverlap mode.
        SpanFullWidth = 4096, /// Extend hit box to the left-most and right-most edges (cover the indent area).
        SpanLabelWidth = 8192, /// Narrow hit box + narrow hovering highlight, will only cover the label text.
        SpanAllColumns = 16384, /// Frame will span all columns of its container table (label will still fit in current column)
        LabelSpanAllColumns = 32768, /// Label will span all columns of its container table
        NavLeftJumpsToParent = 131072, /// Nav: left arrow moves back to parent. This is processed in TreePop() when there's an unfullfilled Left nav request remaining.
        CollapsingHeader = 26,
        DrawLinesNone = 262144, /// No lines drawn
        DrawLinesFull = 524288, /// Horizontal lines to child nodes. Vertical line drawn down to TreePop() position: cover full contents. Faster (for large trees).
        DrawLinesToNodes = 1048576, /// Horizontal lines to child nodes. Vertical line drawn down to bottom-most child node. Slower (for large trees).
    }

    /// Flags for ImGui::Begin()
    /// (Those are per-window flags. There are shared flags in ImGuiIO: io.ConfigWindowsResizeFromEdges and io.ConfigWindowsMoveFromTitleBarOnly)
    enum ImGuiWindowFlags {
        None = 0,
        NoTitleBar = 1, /// Disable title-bar
        NoResize = 2, /// Disable user resizing with the lower-right grip
        NoMove = 4, /// Disable user moving the window
        NoScrollbar = 8, /// Disable scrollbars (window can still scroll with mouse or programmatically)
        NoScrollWithMouse = 16, /// Disable user vertically scrolling with mouse wheel. On child window, mouse wheel will be forwarded to the parent unless NoScrollbar is also set.
        NoCollapse = 32, /// Disable user collapsing window by double-clicking on it. Also referred to as Window Menu Button (e.g. within a docking node).
        AlwaysAutoResize = 64, /// Resize every window to its content every frame
        NoBackground = 128, /// Disable drawing background color (WindowBg, etc.) and outside border. Similar as using SetNextWindowBgAlpha(0.0f).
        NoSavedSettings = 256, /// Never load/save settings in .ini file
        NoMouseInputs = 512, /// Disable catching mouse, hovering test with pass through.
        MenuBar = 1024, /// Has a menu-bar
        HorizontalScrollbar = 2048, /// Allow horizontal scrollbar to appear (off by default). You may use SetNextWindowContentSize(ImVec2(width,0.0f)); prior to calling Begin() to specify width. Read code in imgui_demo in the "Horizontal Scrolling" section.
        NoFocusOnAppearing = 4096, /// Disable taking focus when transitioning from hidden to visible state
        NoBringToFrontOnFocus = 8192, /// Disable bringing window to front when taking focus (e.g. clicking on it or programmatically giving it focus)
        AlwaysVerticalScrollbar = 16384, /// Always show vertical scrollbar (even if ContentSize.y < Size.y)
        AlwaysHorizontalScrollbar = 32768, /// Always show horizontal scrollbar (even if ContentSize.x < Size.x)
        NoNavInputs = 65536, /// No keyboard/gamepad navigation within the window
        NoNavFocus = 131072, /// No focusing toward this window with keyboard/gamepad navigation (e.g. skipped by CTRL+TAB)
        UnsavedDocument = 262144, /// Display a dot next to the title. When used in a tab/docking context, tab is selected when clicking the X + closure is not assumed (will wait for user to stop submitting the tab). Otherwise closure is assumed when pressing the X, so if you keep submitting the tab may reappear at end of tab bar.
        NoDocking = 524288, /// Disable docking of this window
        NoNav = 196608,
        NoDecoration = 43,
        NoInputs = 197120,
        DockNodeHost = 8388608, /// Don't use! For internal use by Begin()/NewFrame()
        ChildWindow = 16777216, /// Don't use! For internal use by BeginChild()
        Tooltip = 33554432, /// Don't use! For internal use by BeginTooltip()
        Popup = 67108864, /// Don't use! For internal use by BeginPopup()
        Modal = 134217728, /// Don't use! For internal use by BeginPopupModal()
        ChildMenu = 268435456, /// Don't use! For internal use by BeginMenu()
    }

    enum ImGuiNavMoveFlags {
        None = 0,
        LoopX = 1, /// On failed request, restart from opposite side
        LoopY = 2,
        WrapX = 4, /// On failed request, request from opposite side one line down (when NavDir==right) or one line up (when NavDir==left)
        WrapY = 8, /// This is not super useful but provided for completeness
        WrapMask_ = 15,
        AllowCurrentNavId = 16, /// Allow scoring and considering the current NavId as a move target candidate. This is used when the move source is offset (e.g. pressing PageDown actually needs to send a Up move request, if we are pressing PageDown from the bottom-most item we need to stay in place)
        AlsoScoreVisibleSet = 32, /// Store alternate result in NavMoveResultLocalVisible that only comprise elements that are already fully visible (used by PageUp/PageDown)
        ScrollToEdgeY = 64, /// Force scrolling to min/max (used by Home/End) /// FIXME-NAV: Aim to remove or reword, probably unnecessary
        Forwarded = 128,
        DebugNoResult = 256, /// Dummy scoring for debug purpose, don't apply result
        FocusApi = 512, /// Requests from focus API can land/focus/activate items even if they are marked with _NoTabStop (see NavProcessItemForTabbingRequest() for details)
        IsTabbing = 1024, /// == Focus + Activate if item is Inputable + DontChangeNavHighlight
        IsPageMove = 2048, /// Identify a PageDown/PageUp request.
        Activate = 4096, /// Activate/select target item.
        NoSelect = 8192, /// Don't trigger selection by not setting g.NavJustMovedTo
        NoSetNavCursorVisible = 16384, /// Do not alter the nav cursor visible state
        NoClearActiveId = 32768, /// (Experimental) Do not clear active id when applying move result
    }

    enum ImGuiTextFlags {
        None = 0,
        NoWidthForLargeClippedText = 1,
    }

    /// Flags for ColorEdit3() / ColorEdit4() / ColorPicker3() / ColorPicker4() / ColorButton()
    enum ImGuiColorEditFlags {
        None = 0,
        NoAlpha = 2, ///              /// ColorEdit, ColorPicker, ColorButton: ignore Alpha component (will only read 3 components from the input pointer).
        NoPicker = 4, ///              /// ColorEdit: disable picker when clicking on color square.
        NoOptions = 8, ///              /// ColorEdit: disable toggling options menu when right-clicking on inputs/small preview.
        NoSmallPreview = 16, ///              /// ColorEdit, ColorPicker: disable color square preview next to the inputs. (e.g. to show only the inputs)
        NoInputs = 32, ///              /// ColorEdit, ColorPicker: disable inputs sliders/text widgets (e.g. to show only the small preview color square).
        NoTooltip = 64, ///              /// ColorEdit, ColorPicker, ColorButton: disable tooltip when hovering the preview.
        NoLabel = 128, ///              /// ColorEdit, ColorPicker: disable display of inline text label (the label is still forwarded to the tooltip and picker).
        NoSidePreview = 256, ///              /// ColorPicker: disable bigger color preview on right side of the picker, use small color square preview instead.
        NoDragDrop = 512, ///              /// ColorEdit: disable drag and drop target. ColorButton: disable drag and drop source.
        NoBorder = 1024, ///              /// ColorButton: disable border (which is enforced by default)
        AlphaOpaque = 2048, ///              /// ColorEdit, ColorPicker, ColorButton: disable alpha in the preview,. Contrary to _NoAlpha it may still be edited when calling ColorEdit4()/ColorPicker4(). For ColorButton() this does the same as _NoAlpha.
        AlphaNoBg = 4096, ///              /// ColorEdit, ColorPicker, ColorButton: disable rendering a checkerboard background behind transparent color.
        AlphaPreviewHalf = 8192, ///              /// ColorEdit, ColorPicker, ColorButton: display half opaque / half transparent preview.
        AlphaBar = 65536, ///              /// ColorEdit, ColorPicker: show vertical alpha bar/gradient in picker.
        HDR = 524288, ///              /// (WIP) ColorEdit: Currently only disable 0.0f..1.0f limits in RGBA edition (note: you probably want to use ImGuiColorEditFlags_Float flag as well).
        DisplayRGB = 1048576, /// [Display]    /// ColorEdit: override _display_ type among RGB/HSV/Hex. ColorPicker: select any combination using one or more of RGB/HSV/Hex.
        DisplayHSV = 2097152, /// [Display]    /// "
        DisplayHex = 4194304, /// [Display]    /// "
        Uint8 = 8388608, /// [DataType]   /// ColorEdit, ColorPicker, ColorButton: _display_ values formatted as 0..255.
        Float = 16777216, /// [DataType]   /// ColorEdit, ColorPicker, ColorButton: _display_ values formatted as 0.0f..1.0f floats instead of 0..255 integers. No round-trip of value via integers.
        PickerHueBar = 33554432, /// [Picker]     /// ColorPicker: bar for Hue, rectangle for Sat/Value.
        PickerHueWheel = 67108864, /// [Picker]     /// ColorPicker: wheel for Hue, triangle for Sat/Value.
        InputRGB = 134217728, /// [Input]      /// ColorEdit, ColorPicker: input and output data in RGB format.
        InputHSV = 268435456, /// [Input]      /// ColorEdit, ColorPicker: input and output data in HSV format.
        DefaultOptions_ = 177209344,
        AlphaMask_ = 14338,
        DisplayMask_ = 7340032,
        DataTypeMask_ = 25165824,
        PickerMask_ = 100663296,
        InputMask_ = 402653184,
    }

    /// Status of a texture to communicate with Renderer Backend.
    enum ImTextureStatus {
        OK = 0,
        Destroyed = 1, /// Backend destroyed the texture.
        WantCreate = 2, /// Requesting backend to create the texture. Set status OK when done.
        WantUpdates = 3, /// Requesting backend to update specific blocks of pixels (write to texture portions which have never been used before). Set status OK when done.
        WantDestroy = 4, /// Requesting backend to destroy the texture. Set status to Destroyed when done.
    }

    enum ImGuiContextHookType {
        NewFramePre = 0,
        NewFramePost = 1,
        EndFramePre = 2,
        EndFramePost = 3,
        RenderPre = 4,
        RenderPost = 5,
        Shutdown = 6,
        PendingRemoval_ = 7,
    }

    /// Flags for ImGui::BeginTabBar()
    enum ImGuiTabBarFlags {
        None = 0,
        Reorderable = 1, /// Allow manually dragging tabs to re-order them + New tabs are appended at the end of list
        AutoSelectNewTabs = 2, /// Automatically select new tabs when they appear
        TabListPopupButton = 4, /// Disable buttons to open the tab list popup
        NoCloseWithMiddleMouseButton = 8, /// Disable behavior of closing tabs (that are submitted with p_open != NULL) with middle mouse button. You may handle this behavior manually on user's side with if (IsItemHovered() && IsMouseClicked(2)) *p_open = false.
        NoTabListScrollingButtons = 16, /// Disable scrolling buttons (apply when fitting policy is ImGuiTabBarFlags_FittingPolicyScroll)
        NoTooltip = 32, /// Disable tooltips when hovering a tab
        DrawSelectedOverline = 64, /// Draw selected overline markers over selected tab
        FittingPolicyResizeDown = 128, /// Resize tabs when they don't fit
        FittingPolicyScroll = 256, /// Add scroll buttons when tabs don't fit
        FittingPolicyMask_ = 384,
        FittingPolicyDefault_ = 128,
    }

    /// Flags for ImDrawList instance. Those are set automatically by ImGui:: functions from ImGuiIO settings, and generally not manipulated directly.
    /// It is however possible to temporarily alter flags between calls to ImDrawList:: functions.
    enum ImDrawListFlags {
        None = 0,
        AntiAliasedLines = 1, /// Enable anti-aliased lines/borders (*2 the number of triangles for 1.0f wide line or lines thin enough to be drawn using textures, otherwise *3 the number of triangles)
        AntiAliasedLinesUseTex = 2, /// Enable anti-aliased lines/borders using textures when possible. Require backend to render with bilinear filtering (NOT point/nearest filtering).
        AntiAliasedFill = 4, /// Enable anti-aliased edge around filled shapes (rounded rectangles, circles).
        AllowVtxOffset = 8, /// Can emit 'VtxOffset > 0' to allow large meshes. Set when 'ImGuiBackendFlags_RendererHasVtxOffset' is enabled.
    }

    /// Flags for Shortcut(), SetNextItemShortcut(),
    /// (and for upcoming extended versions of IsKeyPressed(), IsMouseClicked(), Shortcut(), SetKeyOwner(), SetItemKeyOwner() that are still in imgui_internal.h)
    /// Don't mistake with ImGuiInputTextFlags! (which is for ImGui::InputText() function)
    enum ImGuiInputFlags {
        None = 0,
        Repeat = 1, /// Enable repeat. Return true on successive repeats. Default for legacy IsKeyPressed(). NOT Default for legacy IsMouseClicked(). MUST BE == 1.
        RouteActive = 1024, /// Route to active item only.
        RouteFocused = 2048, /// Route to windows in the focus stack (DEFAULT). Deep-most focused window takes inputs. Active item takes inputs over deep-most focused window.
        RouteGlobal = 4096, /// Global route (unless a focused window or active item registered the route).
        RouteAlways = 8192, /// Do not register route, poll keys directly.
        RouteOverFocused = 16384, /// Option: global route: higher priority than focused route (unless active item in focused route).
        RouteOverActive = 32768, /// Option: global route: higher priority than active item. Unlikely you need to use that: will interfere with every active items, e.g. CTRL+A registered by InputText will be overridden by this. May not be fully honored as user/internal code is likely to always assume they can access keys when active.
        RouteUnlessBgFocused = 65536, /// Option: global route: will not be applied if underlying background/void is focused (== no Dear ImGui windows are focused). Useful for overlay applications.
        RouteFromRootWindow = 131072, /// Option: route evaluated from the point of view of root window rather than current window.
        Tooltip = 262144, /// Automatically display a tooltip when hovering item [BETA] Unsure of right api (opt-in/opt-out)
    }

    /// A key identifier (ImGuiKey_XXX or ImGuiMod_XXX value): can represent Keyboard, Mouse and Gamepad values.
    /// All our named keys are >= 512. Keys value 0 to 511 are left unused and were legacy native/opaque key values (< 1.87).
    /// Support for legacy keys was completely removed in 1.91.5.
    /// Read details about the 1.87+ transition : https://github.com/ocornut/imgui/issues/4921
    /// Note that "Keys" related to physical keys and are not the same concept as input "Characters", the later are submitted via io.AddInputCharacter().
    /// The keyboard key enum values are named after the keys on a standard US keyboard, and on other keyboard types the keys reported may not match the keycaps.
    enum ImGuiKey {
        None = 0,
        NamedKey_BEGIN = 512, /// First valid key value (other than 0)
        Tab = 512, /// == ImGuiKey_NamedKey_BEGIN
        LeftArrow = 513,
        RightArrow = 514,
        UpArrow = 515,
        DownArrow = 516,
        PageUp = 517,
        PageDown = 518,
        Home = 519,
        End = 520,
        Insert = 521,
        Delete = 522,
        Backspace = 523,
        Space = 524,
        Enter = 525,
        Escape = 526,
        LeftCtrl = 527,
        LeftShift = 528,
        LeftAlt = 529,
        LeftSuper = 530,
        RightCtrl = 531,
        RightShift = 532,
        RightAlt = 533,
        RightSuper = 534,
        Menu = 535,
        n0 = 536,
        n1 = 537,
        n2 = 538,
        n3 = 539,
        n4 = 540,
        n5 = 541,
        n6 = 542,
        n7 = 543,
        n8 = 544,
        n9 = 545,
        A = 546,
        B = 547,
        C = 548,
        D = 549,
        E = 550,
        F = 551,
        G = 552,
        H = 553,
        I = 554,
        J = 555,
        K = 556,
        L = 557,
        M = 558,
        N = 559,
        O = 560,
        P = 561,
        Q = 562,
        R = 563,
        S = 564,
        T = 565,
        U = 566,
        V = 567,
        W = 568,
        X = 569,
        Y = 570,
        Z = 571,
        F1 = 572,
        F2 = 573,
        F3 = 574,
        F4 = 575,
        F5 = 576,
        F6 = 577,
        F7 = 578,
        F8 = 579,
        F9 = 580,
        F10 = 581,
        F11 = 582,
        F12 = 583,
        F13 = 584,
        F14 = 585,
        F15 = 586,
        F16 = 587,
        F17 = 588,
        F18 = 589,
        F19 = 590,
        F20 = 591,
        F21 = 592,
        F22 = 593,
        F23 = 594,
        F24 = 595,
        Apostrophe = 596, /// '
        Comma = 597, /// ,
        Minus = 598, /// -
        Period = 599, /// .
        Slash = 600, /// /
        Semicolon = 601, /// ;
        Equal = 602, /// =
        LeftBracket = 603, /// [
        Backslash = 604, /// \ (this text inhibit multiline comment caused by backslash)
        RightBracket = 605, /// ]
        GraveAccent = 606, /// `
        CapsLock = 607,
        ScrollLock = 608,
        NumLock = 609,
        PrintScreen = 610,
        Pause = 611,
        Keypad0 = 612,
        Keypad1 = 613,
        Keypad2 = 614,
        Keypad3 = 615,
        Keypad4 = 616,
        Keypad5 = 617,
        Keypad6 = 618,
        Keypad7 = 619,
        Keypad8 = 620,
        Keypad9 = 621,
        KeypadDecimal = 622,
        KeypadDivide = 623,
        KeypadMultiply = 624,
        KeypadSubtract = 625,
        KeypadAdd = 626,
        KeypadEnter = 627,
        KeypadEqual = 628,
        AppBack = 629, /// Available on some keyboard/mouses. Often referred as "Browser Back"
        AppForward = 630,
        Oem102 = 631, /// Non-US backslash.
        GamepadStart = 632, /// Menu (Xbox)      + (Switch)   Start/Options (PS)
        GamepadBack = 633, /// View (Xbox)      - (Switch)   Share (PS)
        GamepadFaceLeft = 634, /// X (Xbox)         Y (Switch)   Square (PS)        /// Tap: Toggle Menu. Hold: Windowing mode (Focus/Move/Resize windows)
        GamepadFaceRight = 635, /// B (Xbox)         A (Switch)   Circle (PS)        /// Cancel / Close / Exit
        GamepadFaceUp = 636, /// Y (Xbox)         X (Switch)   Triangle (PS)      /// Text Input / On-screen Keyboard
        GamepadFaceDown = 637, /// A (Xbox)         B (Switch)   Cross (PS)         /// Activate / Open / Toggle / Tweak
        GamepadDpadLeft = 638, /// D-pad Left                                       /// Move / Tweak / Resize Window (in Windowing mode)
        GamepadDpadRight = 639, /// D-pad Right                                      /// Move / Tweak / Resize Window (in Windowing mode)
        GamepadDpadUp = 640, /// D-pad Up                                         /// Move / Tweak / Resize Window (in Windowing mode)
        GamepadDpadDown = 641, /// D-pad Down                                       /// Move / Tweak / Resize Window (in Windowing mode)
        GamepadL1 = 642, /// L Bumper (Xbox)  L (Switch)   L1 (PS)            /// Tweak Slower / Focus Previous (in Windowing mode)
        GamepadR1 = 643, /// R Bumper (Xbox)  R (Switch)   R1 (PS)            /// Tweak Faster / Focus Next (in Windowing mode)
        GamepadL2 = 644, /// L Trig. (Xbox)   ZL (Switch)  L2 (PS) [Analog]
        GamepadR2 = 645, /// R Trig. (Xbox)   ZR (Switch)  R2 (PS) [Analog]
        GamepadL3 = 646, /// L Stick (Xbox)   L3 (Switch)  L3 (PS)
        GamepadR3 = 647, /// R Stick (Xbox)   R3 (Switch)  R3 (PS)
        GamepadLStickLeft = 648, /// [Analog]                                         /// Move Window (in Windowing mode)
        GamepadLStickRight = 649, /// [Analog]                                         /// Move Window (in Windowing mode)
        GamepadLStickUp = 650, /// [Analog]                                         /// Move Window (in Windowing mode)
        GamepadLStickDown = 651, /// [Analog]                                         /// Move Window (in Windowing mode)
        GamepadRStickLeft = 652, /// [Analog]
        GamepadRStickRight = 653, /// [Analog]
        GamepadRStickUp = 654, /// [Analog]
        GamepadRStickDown = 655, /// [Analog]
        MouseLeft = 656,
        MouseRight = 657,
        MouseMiddle = 658,
        MouseX1 = 659,
        MouseX2 = 660,
        MouseWheelX = 661,
        MouseWheelY = 662,
        ReservedForModCtrl = 663,
        ReservedForModShift = 664,
        ReservedForModAlt = 665,
        ReservedForModSuper = 666,
        NamedKey_END = 667,
        ImGuiMod_None = 0,
        ImGuiMod_Ctrl = 4096, /// Ctrl (non-macOS), Cmd (macOS)
        ImGuiMod_Shift = 8192, /// Shift
        ImGuiMod_Alt = 16384, /// Option/Menu
        ImGuiMod_Super = 32768, /// Windows/Super (non-macOS), Ctrl (macOS)
        ImGuiMod_Mask_ = 61440, /// 4-bits
        NamedKey_COUNT = 155,
    }

    /// Enumeration for ImGui::SetNextWindow***(), SetWindow***(), SetNextItem***() functions
    /// Represent a condition.
    /// Important: Treat as a regular enum! Do NOT combine multiple values using binary operators! All the functions above treat 0 as a shortcut to ImGuiCond_Always.
    enum ImGuiCond {
        None = 0, /// No condition (always set the variable), same as _Always
        Always = 1, /// No condition (always set the variable), same as _None
        Once = 2, /// Set the variable once per runtime session (only the first call will succeed)
        FirstUseEver = 4, /// Set the variable if the object/window has no persistently saved data (no entry in .ini file)
        Appearing = 8, /// Set the variable if the object/window is appearing after being hidden/inactive (or the first time)
    }

    /// Flags for ImGui::Selectable()
    enum ImGuiSelectableFlags {
        None = 0,
        NoAutoClosePopups = 1, /// Clicking this doesn't close parent popup window (overrides ImGuiItemFlags_AutoClosePopups)
        SpanAllColumns = 2, /// Frame will span all columns of its container table (text will still fit in current column)
        AllowDoubleClick = 4, /// Generate press events on double clicks too
        Disabled = 8, /// Cannot be selected, display grayed out text
        AllowOverlap = 16, /// (WIP) Hit testing to allow subsequent widgets to overlap this one
        Highlight = 32, /// Make the item be displayed as if it is hovered
    }

    enum ImGuiNextWindowDataFlags {
        None = 0,
        HasPos = 1,
        HasSize = 2,
        HasContentSize = 4,
        HasCollapsed = 8,
        HasSizeConstraint = 16,
        HasFocus = 32,
        HasBgAlpha = 64,
        HasScroll = 128,
        HasWindowFlags = 256,
        HasChildFlags = 512,
        HasRefreshPolicy = 1024,
        HasViewport = 2048,
        HasDock = 4096,
        HasWindowClass = 8192,
    }

    /// Enumeration for PushStyleVar() / PopStyleVar() to temporarily modify the ImGuiStyle structure.
    /// - The enum only refers to fields of ImGuiStyle which makes sense to be pushed/popped inside UI code.
    ///   During initialization or between frames, feel free to just poke into ImGuiStyle directly.
    /// - Tip: Use your programming IDE navigation facilities on the names in the _second column_ below to find the actual members and their description.
    ///   - In Visual Studio: CTRL+comma ("Edit.GoToAll") can follow symbols inside comments, whereas CTRL+F12 ("Edit.GoToImplementation") cannot.
    ///   - In Visual Studio w/ Visual Assist installed: ALT+G ("VAssistX.GoToImplementation") can also follow symbols inside comments.
    ///   - In VS Code, CLion, etc.: CTRL+click can follow symbols inside comments.
    /// - When changing this enum, you need to update the associated internal table GStyleVarInfo[] accordingly. This is where we link enum values to members offset/type.
    enum ImGuiStyleVar {
        Alpha = 0, /// float     Alpha
        DisabledAlpha = 1, /// float     DisabledAlpha
        WindowPadding = 2, /// ImVec2    WindowPadding
        WindowRounding = 3, /// float     WindowRounding
        WindowBorderSize = 4, /// float     WindowBorderSize
        WindowMinSize = 5, /// ImVec2    WindowMinSize
        WindowTitleAlign = 6, /// ImVec2    WindowTitleAlign
        ChildRounding = 7, /// float     ChildRounding
        ChildBorderSize = 8, /// float     ChildBorderSize
        PopupRounding = 9, /// float     PopupRounding
        PopupBorderSize = 10, /// float     PopupBorderSize
        FramePadding = 11, /// ImVec2    FramePadding
        FrameRounding = 12, /// float     FrameRounding
        FrameBorderSize = 13, /// float     FrameBorderSize
        ItemSpacing = 14, /// ImVec2    ItemSpacing
        ItemInnerSpacing = 15, /// ImVec2    ItemInnerSpacing
        IndentSpacing = 16, /// float     IndentSpacing
        CellPadding = 17, /// ImVec2    CellPadding
        ScrollbarSize = 18, /// float     ScrollbarSize
        ScrollbarRounding = 19, /// float     ScrollbarRounding
        GrabMinSize = 20, /// float     GrabMinSize
        GrabRounding = 21, /// float     GrabRounding
        ImageBorderSize = 22, /// float     ImageBorderSize
        TabRounding = 23, /// float     TabRounding
        TabBorderSize = 24, /// float     TabBorderSize
        TabBarBorderSize = 25, /// float     TabBarBorderSize
        TabBarOverlineSize = 26, /// float     TabBarOverlineSize
        TableAngledHeadersAngle = 27, /// float     TableAngledHeadersAngle
        TableAngledHeadersTextAlign = 28, /// ImVec2  TableAngledHeadersTextAlign
        TreeLinesSize = 29, /// float     TreeLinesSize
        TreeLinesRounding = 30, /// float     TreeLinesRounding
        ButtonTextAlign = 31, /// ImVec2    ButtonTextAlign
        SelectableTextAlign = 32, /// ImVec2    SelectableTextAlign
        SeparatorTextBorderSize = 33, /// float     SeparatorTextBorderSize
        SeparatorTextAlign = 34, /// ImVec2    SeparatorTextAlign
        SeparatorTextPadding = 35, /// ImVec2    SeparatorTextPadding
        DockingSeparatorSize = 36, /// float     DockingSeparatorSize
        COUNT = 37,
    }

    /// Extend ImGuiInputTextFlags_
    enum ImGuiInputTextFlagsI : ImGuiInputTextFlags {
        Multiline = cast(ImGuiInputTextFlags)67108864, /// For internal use by InputTextMultiline()
        MergedItem = cast(ImGuiInputTextFlags)134217728, /// For internal use by TempInputText(), will skip calling ItemAdd(). Require bounding-box to strictly match.
        LocalizeDecimalPoint = cast(ImGuiInputTextFlags)268435456, /// For internal use by InputScalar() and TempInputScalar()
    }

    /// Flags for ImGui::BeginCombo()
    enum ImGuiComboFlags {
        None = 0,
        PopupAlignLeft = 1, /// Align the popup toward the left by default
        HeightSmall = 2, /// Max ~4 items visible. Tip: If you want your combo popup to be a specific size you can use SetNextWindowSizeConstraints() prior to calling BeginCombo()
        HeightRegular = 4, /// Max ~8 items visible (default)
        HeightLarge = 8, /// Max ~20 items visible
        HeightLargest = 16, /// As many fitting items as possible
        NoArrowButton = 32, /// Display on the preview box without the square arrow button
        NoPreview = 64, /// Display only a square arrow button
        WidthFitPreview = 128, /// Width dynamically calculated from preview contents
        HeightMask_ = 30,
    }

    /// Extend ImGuiItemFlags
    /// - input: PushItemFlag() manipulates g.CurrentItemFlags, g.NextItemData.ItemFlags, ItemAdd() calls may add extra flags too.
    /// - output: stored in g.LastItemData.ItemFlags
    enum ImGuiItemFlagsI : ImGuiItemFlags {
        Disabled = cast(ImGuiItemFlags)1024, /// false     /// Disable interactions (DOES NOT affect visuals. DO NOT mix direct use of this with BeginDisabled(). See BeginDisabled()/EndDisabled() for full disable feature, and github #211).
        ReadOnly = cast(ImGuiItemFlags)2048, /// false     /// [ALPHA] Allow hovering interactions but underlying value is not changed.
        MixedValue = cast(ImGuiItemFlags)4096, /// false     /// [BETA] Represent a mixed/indeterminate value, generally multi-selection where values differ. Currently only supported by Checkbox() (later should support all sorts of widgets)
        NoWindowHoverableCheck = cast(ImGuiItemFlags)8192, /// false     /// Disable hoverable check in ItemHoverable()
        AllowOverlap = cast(ImGuiItemFlags)16384, /// false     /// Allow being overlapped by another widget. Not-hovered to Hovered transition deferred by a frame.
        NoNavDisableMouseHover = cast(ImGuiItemFlags)32768, /// false     /// Nav keyboard/gamepad mode doesn't disable hover highlight (behave as if NavHighlightItemUnderNav==false).
        NoMarkEdited = cast(ImGuiItemFlags)65536, /// false     /// Skip calling MarkItemEdited()
        NoFocus = cast(ImGuiItemFlags)131072, /// false     /// [EXPERIMENTAL: Not very well specced] Clicking doesn't take focus. Automatically sets ImGuiButtonFlags_NoFocus + ImGuiButtonFlags_NoNavFocus in ButtonBehavior().
        Inputable = cast(ImGuiItemFlags)1048576, /// false     /// [WIP] Auto-activate input mode when tab focused. Currently only used and supported by a few items before it becomes a generic feature.
        HasSelectionUserData = cast(ImGuiItemFlags)2097152, /// false     /// Set by SetNextItemSelectionUserData()
        IsMultiSelect = cast(ImGuiItemFlags)4194304, /// false     /// Set by SetNextItemSelectionUserData()
        Default_ = cast(ImGuiItemFlags)16, /// Please don't change, use PushItemFlag() instead.
    }

    /// Flags for ImFontAtlas build
    enum ImFontAtlasFlags {
        None = 0,
        NoPowerOfTwoHeight = 1, /// Don't round the height to next power of two
        NoMouseCursors = 2, /// Don't build software mouse cursors into the atlas (save a little texture memory)
        NoBakedLines = 4, /// Don't build thick line textures into the atlas (save a little texture memory, allow support for point/nearest filtering). The AntiAliasedLinesUseTex features uses them, otherwise they will be rendered using polygons (more expensive for CPU/GPU).
    }

    /// Backend capabilities flags stored in io.BackendFlags. Set by imgui_impl_xxx or custom backend.
    enum ImGuiBackendFlags {
        None = 0,
        HasGamepad = 1, /// Backend Platform supports gamepad and currently has one connected.
        HasMouseCursors = 2, /// Backend Platform supports honoring GetMouseCursor() value to change the OS cursor shape.
        HasSetMousePos = 4, /// Backend Platform supports io.WantSetMousePos requests to reposition the OS mouse position (only used if io.ConfigNavMoveSetMousePos is set).
        RendererHasVtxOffset = 8, /// Backend Renderer supports ImDrawCmd::VtxOffset. This enables output of large meshes (64K+ vertices) while still using 16-bit indices.
        RendererHasTextures = 16, /// Backend Renderer supports ImTextureData requests to create/update/destroy textures. This enables incremental texture updates and texture reloads.
        PlatformHasViewports = 1024, /// Backend Platform supports multiple viewports.
        HasMouseHoveredViewport = 2048, /// Backend Platform supports calling io.AddMouseViewportEvent() with the viewport under the mouse. IF POSSIBLE, ignore viewports with the ImGuiViewportFlags_NoInputs flag (Win32 backend, GLFW 3.30+ backend can do this, SDL backend cannot). If this cannot be done, Dear ImGui needs to use a flawed heuristic to find the viewport under.
        RendererHasViewports = 4096, /// Backend Renderer supports multiple viewports.
    }

    enum ImGuiWindowRefreshFlags {
        None = 0,
        TryToAvoidRefresh = 1, /// [EXPERIMENTAL] Try to keep existing contents, USER MUST NOT HONOR BEGIN() RETURNING FALSE AND NOT APPEND.
        RefreshOnHover = 2, /// [EXPERIMENTAL] Always refresh on hover
        RefreshOnFocus = 4, /// [EXPERIMENTAL] Always refresh on focus
    }

    /// Flags for ImGui::PushItemFlag()
    /// (Those are shared by all items)
    enum ImGuiItemFlags {
        None = 0, /// (Default)
        NoTabStop = 1, /// false    /// Disable keyboard tabbing. This is a "lighter" version of ImGuiItemFlags_NoNav.
        NoNav = 2, /// false    /// Disable any form of focusing (keyboard/gamepad directional navigation and SetKeyboardFocusHere() calls).
        NoNavDefaultFocus = 4, /// false    /// Disable item being a candidate for default focus (e.g. used by title bar items).
        ButtonRepeat = 8, /// false    /// Any button-like behavior will have repeat mode enabled (based on io.KeyRepeatDelay and io.KeyRepeatRate values). Note that you can also call IsItemActive() after any button to tell if it is being held.
        AutoClosePopups = 16, /// true     /// MenuItem()/Selectable() automatically close their parent popup window.
        AllowDuplicateId = 32, /// false    /// Allow submitting an item with the same identifier as an item already submitted this frame without triggering a warning tooltip if io.ConfigDebugHighlightIdConflicts is set.
    }

    /// Flags for LogBegin() text capturing function
    enum ImGuiLogFlags {
        None = 0,
        OutputTTY = 1,
        OutputFile = 2,
        OutputBuffer = 4,
        OutputClipboard = 8,
        OutputMask_ = 15,
    }

    enum ImGuiNavLayer {
        Main = 0, /// Main scrolling layer
        Menu = 1, /// Menu layer (access with Alt)
        COUNT = 2,
    }

    /// We intentionally support a limited amount of texture formats to limit burden on CPU-side code and extension.
    /// Most standard backends only support RGBA32 but we provide a single channel option for low-resource/embedded systems.
    enum ImTextureFormat {
        RGBA32 = 0, /// 4 components per pixel, each is unsigned 8-bit. Total size = TexWidth * TexHeight * 4
        Alpha8 = 1, /// 1 component per pixel, each is unsigned 8-bit. Total size = TexWidth * TexHeight
    }

    enum ImGuiDockNodeState {
        Unknown = 0,
        HostWindowHiddenBecauseSingleWindow = 1,
        HostWindowHiddenBecauseWindowsAreResizing = 2,
        HostWindowVisible = 3,
    }

    /// X/Y enums are fixed to 0/1 so they may be used to index ImVec2
    enum ImGuiAxis {
        None = -1,
        X = 0,
        Y = 1,
    }

    /// Extend ImGuiButtonFlags_
    enum ImGuiButtonFlagsI : ImGuiButtonFlags {
        PressedOnClick = cast(ImGuiButtonFlags)16, /// return true on click (mouse down event)
        PressedOnClickRelease = cast(ImGuiButtonFlags)32, /// [Default] return true on click + release on same item <-- this is what the majority of Button are using
        PressedOnClickReleaseAnywhere = cast(ImGuiButtonFlags)64, /// return true on click + release even if the release event is not done while hovering the item
        PressedOnRelease = cast(ImGuiButtonFlags)128, /// return true on release (default requires click+release)
        PressedOnDoubleClick = cast(ImGuiButtonFlags)256, /// return true on double-click (default requires click+release)
        PressedOnDragDropHold = cast(ImGuiButtonFlags)512, /// return true when held into while we are drag and dropping another item (used by e.g. tree nodes, collapsing headers)
        FlattenChildren = cast(ImGuiButtonFlags)2048, /// allow interactions even if a child window is overlapping
        AllowOverlap = cast(ImGuiButtonFlags)4096, /// require previous frame HoveredId to either match id or be null before being usable.
        AlignTextBaseLine = cast(ImGuiButtonFlags)32768, /// vertically align button to match text baseline - ButtonEx() only /// FIXME: Should be removed and handled by SmallButton(), not possible currently because of DC.CursorPosPrevLine
        NoKeyModsAllowed = cast(ImGuiButtonFlags)65536, /// disable mouse interaction if a key modifier is held
        NoHoldingActiveId = cast(ImGuiButtonFlags)131072, /// don't set ActiveId while holding the mouse (ImGuiButtonFlags_PressedOnClick only)
        NoNavFocus = cast(ImGuiButtonFlags)262144, /// don't override navigation focus when activated (FIXME: this is essentially used every time an item uses ImGuiItemFlags_NoNav, but because legacy specs don't requires LastItemData to be set ButtonBehavior(), we can't poll g.LastItemData.ItemFlags)
        NoHoveredOnFocus = cast(ImGuiButtonFlags)524288, /// don't report as hovered when nav focus is on this item
        NoSetKeyOwner = cast(ImGuiButtonFlags)1048576, /// don't set key/input owner on the initial click (note: mouse buttons are keys! often, the key in question will be ImGuiKey_MouseLeft!)
        NoTestKeyOwner = cast(ImGuiButtonFlags)2097152, /// don't test key/input owner when polling the key (note: mouse buttons are keys! often, the key in question will be ImGuiKey_MouseLeft!)
        NoFocus = cast(ImGuiButtonFlags)4194304, /// [EXPERIMENTAL: Not very well specced]. Don't focus parent window when clicking.
        PressedOnMask_ = cast(ImGuiButtonFlags)1008,
        PressedOnDefault_ = cast(ImGuiButtonFlags)32,
    }

    /// Flags for ImGui::BeginDragDropSource(), ImGui::AcceptDragDropPayload()
    enum ImGuiDragDropFlags {
        None = 0,
        SourceNoPreviewTooltip = 1, /// Disable preview tooltip. By default, a successful call to BeginDragDropSource opens a tooltip so you can display a preview or description of the source contents. This flag disables this behavior.
        SourceNoDisableHover = 2, /// By default, when dragging we clear data so that IsItemHovered() will return false, to avoid subsequent user code submitting tooltips. This flag disables this behavior so you can still call IsItemHovered() on the source item.
        SourceNoHoldToOpenOthers = 4, /// Disable the behavior that allows to open tree nodes and collapsing header by holding over them while dragging a source item.
        SourceAllowNullID = 8, /// Allow items such as Text(), Image() that have no unique identifier to be used as drag source, by manufacturing a temporary identifier based on their window-relative position. This is extremely unusual within the dear imgui ecosystem and so we made it explicit.
        SourceExtern = 16, /// External source (from outside of dear imgui), won't attempt to read current item/window info. Will always return true. Only one Extern source can be active simultaneously.
        PayloadAutoExpire = 32, /// Automatically expire the payload if the source cease to be submitted (otherwise payloads are persisting while being dragged)
        PayloadNoCrossContext = 64, /// Hint to specify that the payload may not be copied outside current dear imgui context.
        PayloadNoCrossProcess = 128, /// Hint to specify that the payload may not be copied outside current process.
        AcceptBeforeDelivery = 1024, /// AcceptDragDropPayload() will returns true even before the mouse button is released. You can then call IsDelivery() to test if the payload needs to be delivered.
        AcceptNoDrawDefaultRect = 2048, /// Do not draw the default highlight rectangle when hovering over target.
        AcceptNoPreviewTooltip = 4096, /// Request hiding the BeginDragDropSource tooltip from the BeginDragDropTarget site.
        AcceptPeekOnly = 3072, /// For peeking ahead and inspecting the payload before delivery.
    }

    /// Selection request type
    enum ImGuiSelectionRequestType {
        None = 0,
        SetAll = 1, /// Request app to clear selection (if Selected==false) or select all items (if Selected==true). We cannot set RangeFirstItem/RangeLastItem as its contents is entirely up to user (not necessarily an index)
        SetRange = 2, /// Request app to select/unselect [RangeFirstItem..RangeLastItem] items (inclusive) based on value of Selected. Only EndMultiSelect() request this, app code can read after BeginMultiSelect() and it will always be false.
    }

    /// See IMGUI_DEBUG_LOG() and IMGUI_DEBUG_LOG_XXX() macros.
    enum ImGuiDebugLogFlags {
        None = 0,
        EventError = 1, /// Error submitted by IM_ASSERT_USER_ERROR()
        EventActiveId = 2,
        EventFocus = 4,
        EventPopup = 8,
        EventNav = 16,
        EventClipper = 32,
        EventSelection = 64,
        EventIO = 128,
        EventFont = 256,
        EventInputRouting = 512,
        EventDocking = 1024,
        EventViewport = 2048,
        EventMask_ = 4095,
        OutputToTTY = 1048576, /// Also send output to TTY
        OutputToTestEngine = 2097152, /// Also send output to Test Engine
    }

    /// A sorting direction
    enum ImGuiSortDirection {
        None = 0,
        Ascending = 1, /// Ascending = 0->9, A->Z etc.
        Descending = 2, /// Descending = 9->0, Z->A etc.
    }

    /// Flags for ImGui::BeginTable()
    /// - Important! Sizing policies have complex and subtle side effects, much more so than you would expect.
    ///   Read comments/demos carefully + experiment with live demos to get acquainted with them.
    /// - The DEFAULT sizing policies are:
    ///    - Default to ImGuiTableFlags_SizingFixedFit    if ScrollX is on, or if host window has ImGuiWindowFlags_AlwaysAutoResize.
    ///    - Default to ImGuiTableFlags_SizingStretchSame if ScrollX is off.
    /// - When ScrollX is off:
    ///    - Table defaults to ImGuiTableFlags_SizingStretchSame -> all Columns defaults to ImGuiTableColumnFlags_WidthStretch with same weight.
    ///    - Columns sizing policy allowed: Stretch (default), Fixed/Auto.
    ///    - Fixed Columns (if any) will generally obtain their requested width (unless the table cannot fit them all).
    ///    - Stretch Columns will share the remaining width according to their respective weight.
    ///    - Mixed Fixed/Stretch columns is possible but has various side-effects on resizing behaviors.
    ///      The typical use of mixing sizing policies is: any number of LEADING Fixed columns, followed by one or two TRAILING Stretch columns.
    ///      (this is because the visible order of columns have subtle but necessary effects on how they react to manual resizing).
    /// - When ScrollX is on:
    ///    - Table defaults to ImGuiTableFlags_SizingFixedFit -> all Columns defaults to ImGuiTableColumnFlags_WidthFixed
    ///    - Columns sizing policy allowed: Fixed/Auto mostly.
    ///    - Fixed Columns can be enlarged as needed. Table will show a horizontal scrollbar if needed.
    ///    - When using auto-resizing (non-resizable) fixed columns, querying the content width to use item right-alignment e.g. SetNextItemWidth(-FLT_MIN) doesn't make sense, would create a feedback loop.
    ///    - Using Stretch columns OFTEN DOES NOT MAKE SENSE if ScrollX is on, UNLESS you have specified a value for 'inner_width' in BeginTable().
    ///      If you specify a value for 'inner_width' then effectively the scrolling space is known and Stretch or mixed Fixed/Stretch columns become meaningful again.
    /// - Read on documentation at the top of imgui_tables.cpp for details.
    enum ImGuiTableFlags {
        None = 0,
        Resizable = 1, /// Enable resizing columns.
        Reorderable = 2, /// Enable reordering columns in header row (need calling TableSetupColumn() + TableHeadersRow() to display headers)
        Hideable = 4, /// Enable hiding/disabling columns in context menu.
        Sortable = 8, /// Enable sorting. Call TableGetSortSpecs() to obtain sort specs. Also see ImGuiTableFlags_SortMulti and ImGuiTableFlags_SortTristate.
        NoSavedSettings = 16, /// Disable persisting columns order, width and sort settings in the .ini file.
        ContextMenuInBody = 32, /// Right-click on columns body/contents will display table context menu. By default it is available in TableHeadersRow().
        RowBg = 64, /// Set each RowBg color with ImGuiCol_TableRowBg or ImGuiCol_TableRowBgAlt (equivalent of calling TableSetBgColor with ImGuiTableBgFlags_RowBg0 on each row manually)
        BordersInnerH = 128, /// Draw horizontal borders between rows.
        BordersOuterH = 256, /// Draw horizontal borders at the top and bottom.
        BordersInnerV = 512, /// Draw vertical borders between columns.
        BordersOuterV = 1024, /// Draw vertical borders on the left and right sides.
        BordersH = 384, /// Draw horizontal borders.
        BordersV = 1536, /// Draw vertical borders.
        BordersInner = 640, /// Draw inner borders.
        BordersOuter = 1280, /// Draw outer borders.
        Borders = 1920, /// Draw all borders.
        NoBordersInBody = 2048, /// [ALPHA] Disable vertical borders in columns Body (borders will always appear in Headers). -> May move to style
        NoBordersInBodyUntilResize = 4096, /// [ALPHA] Disable vertical borders in columns Body until hovered for resize (borders will always appear in Headers). -> May move to style
        SizingFixedFit = 8192, /// Columns default to _WidthFixed or _WidthAuto (if resizable or not resizable), matching contents width.
        SizingFixedSame = 16384, /// Columns default to _WidthFixed or _WidthAuto (if resizable or not resizable), matching the maximum contents width of all columns. Implicitly enable ImGuiTableFlags_NoKeepColumnsVisible.
        SizingStretchProp = 24576, /// Columns default to _WidthStretch with default weights proportional to each columns contents widths.
        SizingStretchSame = 32768, /// Columns default to _WidthStretch with default weights all equal, unless overridden by TableSetupColumn().
        NoHostExtendX = 65536, /// Make outer width auto-fit to columns, overriding outer_size.x value. Only available when ScrollX/ScrollY are disabled and Stretch columns are not used.
        NoHostExtendY = 131072, /// Make outer height stop exactly at outer_size.y (prevent auto-extending table past the limit). Only available when ScrollX/ScrollY are disabled. Data below the limit will be clipped and not visible.
        NoKeepColumnsVisible = 262144, /// Disable keeping column always minimally visible when ScrollX is off and table gets too small. Not recommended if columns are resizable.
        PreciseWidths = 524288, /// Disable distributing remainder width to stretched columns (width allocation on a 100-wide table with 3 columns: Without this flag: 33,33,34. With this flag: 33,33,33). With larger number of columns, resizing will appear to be less smooth.
        NoClip = 1048576, /// Disable clipping rectangle for every individual columns (reduce draw command count, items will be able to overflow into other columns). Generally incompatible with TableSetupScrollFreeze().
        PadOuterX = 2097152, /// Default if BordersOuterV is on. Enable outermost padding. Generally desirable if you have headers.
        NoPadOuterX = 4194304, /// Default if BordersOuterV is off. Disable outermost padding.
        NoPadInnerX = 8388608, /// Disable inner padding between columns (double inner padding if BordersOuterV is on, single inner padding if BordersOuterV is off).
        ScrollX = 16777216, /// Enable horizontal scrolling. Require 'outer_size' parameter of BeginTable() to specify the container size. Changes default sizing policy. Because this creates a child window, ScrollY is currently generally recommended when using ScrollX.
        ScrollY = 33554432, /// Enable vertical scrolling. Require 'outer_size' parameter of BeginTable() to specify the container size.
        SortMulti = 67108864, /// Hold shift when clicking headers to sort on multiple column. TableGetSortSpecs() may return specs where (SpecsCount > 1).
        SortTristate = 134217728, /// Allow no sorting, disable default sorting. TableGetSortSpecs() may return specs where (SpecsCount == 0).
        HighlightHoveredColumn = 268435456, /// Highlight column headers when hovered (may evolve into a fuller highlight)
        SizingMask_ = 57344,
    }

    /// A cardinal direction
    enum ImGuiDir {
        None = -1,
        Left = 0,
        Right = 1,
        Up = 2,
        Down = 3,
        COUNT = 4,
    }

    /// Early work-in-progress API for ScrollToItem()
    enum ImGuiScrollFlags {
        None = 0,
        KeepVisibleEdgeX = 1, /// If item is not visible: scroll as little as possible on X axis to bring item back into view [default for X axis]
        KeepVisibleEdgeY = 2, /// If item is not visible: scroll as little as possible on Y axis to bring item back into view [default for Y axis for windows that are already visible]
        KeepVisibleCenterX = 4, /// If item is not visible: scroll to make the item centered on X axis [rarely used]
        KeepVisibleCenterY = 8, /// If item is not visible: scroll to make the item centered on Y axis
        AlwaysCenterX = 16, /// Always center the result item on X axis [rarely used]
        AlwaysCenterY = 32, /// Always center the result item on Y axis [default for Y axis for appearing window)
        NoScrollParent = 64, /// Disable forwarding scrolling to parent window if required to keep item/rect visible (only scroll window the function was applied to).
        MaskX_ = 21,
        MaskY_ = 42,
    }

    /// Extend ImGuiTreeNodeFlags_
    enum ImGuiTreeNodeFlagsI : ImGuiTreeNodeFlags {
        NoNavFocus = cast(ImGuiTreeNodeFlags)134217728, /// Don't claim nav focus when interacting with this item (#8551)
        ClipLabelForTrailingButton = cast(ImGuiTreeNodeFlags)268435456, /// FIXME-WIP: Hard-coded for CollapsingHeader()
        UpsideDownArrow = cast(ImGuiTreeNodeFlags)536870912, /// FIXME-WIP: Turn Down arrow into an Up arrow, for reversed trees (#6517)
        OpenOnMask_ = cast(ImGuiTreeNodeFlags)192,
        DrawLinesMask_ = cast(ImGuiTreeNodeFlags)1835008,
    }

    /// Flags for ImDrawList functions
    /// (Legacy: bit 0 must always correspond to ImDrawFlags_Closed to be backward compatible with old API using a bool. Bits 1..3 must be unused)
    enum ImDrawFlags {
        None = 0,
        Closed = 1, /// PathStroke(), AddPolyline(): specify that shape should be closed (Important: this is always == 1 for legacy reason)
        RoundCornersTopLeft = 16, /// AddRect(), AddRectFilled(), PathRect(): enable rounding top-left corner only (when rounding > 0.0f, we default to all corners). Was 0x01.
        RoundCornersTopRight = 32, /// AddRect(), AddRectFilled(), PathRect(): enable rounding top-right corner only (when rounding > 0.0f, we default to all corners). Was 0x02.
        RoundCornersBottomLeft = 64, /// AddRect(), AddRectFilled(), PathRect(): enable rounding bottom-left corner only (when rounding > 0.0f, we default to all corners). Was 0x04.
        RoundCornersBottomRight = 128, /// AddRect(), AddRectFilled(), PathRect(): enable rounding bottom-right corner only (when rounding > 0.0f, we default to all corners). Wax 0x08.
        RoundCornersNone = 256, /// AddRect(), AddRectFilled(), PathRect(): disable rounding on all corners (when rounding > 0.0f). This is NOT zero, NOT an implicit flag!
        RoundCornersTop = 48,
        RoundCornersBottom = 192,
        RoundCornersLeft = 80,
        RoundCornersRight = 160,
        RoundCornersAll = 240,
        RoundCornersDefault_ = 240, /// Default to ALL corners if none of the _RoundCornersXX flags are specified.
        RoundCornersMask_ = 496,
    }

    /// Flags for ImGui::IsWindowFocused()
    enum ImGuiFocusedFlags {
        None = 0,
        ChildWindows = 1, /// Return true if any children of the window is focused
        RootWindow = 2, /// Test from root window (top most parent of the current hierarchy)
        AnyWindow = 4, /// Return true if any window is focused. Important: If you are trying to tell how to dispatch your low-level inputs, do NOT use this. Use 'io.WantCaptureMouse' instead! Please read the FAQ!
        NoPopupHierarchy = 8, /// Do not consider popup hierarchy (do not treat popup emitter as parent of popup) (when used with _ChildWindows or _RootWindow)
        DockHierarchy = 16, /// Consider docking hierarchy (treat dockspace host as parent of docked window) (when used with _ChildWindows or _RootWindow)
        RootAndChildWindows = 3,
    }

    /// Extend ImGuiTabItemFlags_
    enum ImGuiTabItemFlagsI : ImGuiTabItemFlags {
        SectionMask_ = cast(ImGuiTabItemFlags)192,
        NoCloseButton = cast(ImGuiTabItemFlags)1048576, /// Track whether p_open was set or not (we'll need this info on the next frame to recompute ContentWidth during layout)
        Button = cast(ImGuiTabItemFlags)2097152, /// Used by TabItemButton, change the tab item behavior to mimic a button
        Invisible = cast(ImGuiTabItemFlags)4194304, /// To reserve space e.g. with ImGuiTabItemFlags_Leading
        Unsorted = cast(ImGuiTabItemFlags)8388608, /// [Docking] Trailing tabs with the _Unsorted flag will be sorted based on the DockOrder of their Window.
    }

    /// Flags for DragFloat(), DragInt(), SliderFloat(), SliderInt() etc.
    /// We use the same sets of flags for DragXXX() and SliderXXX() functions as the features are the same and it makes it easier to swap them.
    /// (Those are per-item flags. There is shared behavior flag too: ImGuiIO: io.ConfigDragClickToInputText)
    enum ImGuiSliderFlags {
        None = 0,
        Logarithmic = 32, /// Make the widget logarithmic (linear otherwise). Consider using ImGuiSliderFlags_NoRoundToFormat with this if using a format-string with small amount of digits.
        NoRoundToFormat = 64, /// Disable rounding underlying value to match precision of the display format string (e.g. %.3f values are rounded to those 3 digits).
        NoInput = 128, /// Disable CTRL+Click or Enter key allowing to input text directly into the widget.
        WrapAround = 256, /// Enable wrapping around from max to min and from min to max. Only supported by DragXXX() functions for now.
        ClampOnInput = 512, /// Clamp value to min/max bounds when input manually with CTRL+Click. By default CTRL+Click allows going out of bounds.
        ClampZeroRange = 1024, /// Clamp even if min==max==0.0f. Otherwise due to legacy reason DragXXX functions don't clamp with those values. When your clamping limits are dynamic you almost always want to use it.
        NoSpeedTweaks = 2048, /// Disable keyboard modifiers altering tweak speed. Useful if you want to alter tweak speed yourself based on your own logic.
        AlwaysClamp = 1536,
        InvalidMask_ = 1879048207, /// [Internal] We treat using those bits as being potentially a 'float power' argument from the previous API that has got miscast to this enum, and will trigger an assert if needed.
    }

    /// A primary data type
    enum ImGuiDataType {
        S8 = 0, /// signed char / char (with sensible compilers)
        U8 = 1, /// unsigned char
        S16 = 2, /// short
        U16 = 3, /// unsigned short
        S32 = 4, /// int
        U32 = 5, /// unsigned int
        S64 = 6, /// long long / __int64
        U64 = 7, /// unsigned long long / unsigned __int64
        Float = 8, /// float
        Double = 9, /// double
        Bool = 10, /// bool (provided for user convenience, not supported by scalar widgets)
        String = 11, /// char* (provided for user convenience, not supported by scalar widgets)
        COUNT = 12,
    }

    /// Extend ImGuiComboFlags_
    enum ImGuiComboFlagsI : ImGuiComboFlags {
        CustomPreview = cast(ImGuiComboFlags)1048576, /// enable BeginComboPreview()
    }

    /// Enumeration for PushStyleColor() / PopStyleColor()
    enum ImGuiCol {
        Text = 0,
        TextDisabled = 1,
        WindowBg = 2, /// Background of normal windows
        ChildBg = 3, /// Background of child windows
        PopupBg = 4, /// Background of popups, menus, tooltips windows
        Border = 5,
        BorderShadow = 6,
        FrameBg = 7, /// Background of checkbox, radio button, plot, slider, text input
        FrameBgHovered = 8,
        FrameBgActive = 9,
        TitleBg = 10, /// Title bar
        TitleBgActive = 11, /// Title bar when focused
        TitleBgCollapsed = 12, /// Title bar when collapsed
        MenuBarBg = 13,
        ScrollbarBg = 14,
        ScrollbarGrab = 15,
        ScrollbarGrabHovered = 16,
        ScrollbarGrabActive = 17,
        CheckMark = 18, /// Checkbox tick and RadioButton circle
        SliderGrab = 19,
        SliderGrabActive = 20,
        Button = 21,
        ButtonHovered = 22,
        ButtonActive = 23,
        Header = 24, /// Header* colors are used for CollapsingHeader, TreeNode, Selectable, MenuItem
        HeaderHovered = 25,
        HeaderActive = 26,
        Separator = 27,
        SeparatorHovered = 28,
        SeparatorActive = 29,
        ResizeGrip = 30, /// Resize grip in lower-right and lower-left corners of windows.
        ResizeGripHovered = 31,
        ResizeGripActive = 32,
        InputTextCursor = 33, /// InputText cursor/caret
        TabHovered = 34, /// Tab background, when hovered
        Tab = 35, /// Tab background, when tab-bar is focused & tab is unselected
        TabSelected = 36, /// Tab background, when tab-bar is focused & tab is selected
        TabSelectedOverline = 37, /// Tab horizontal overline, when tab-bar is focused & tab is selected
        TabDimmed = 38, /// Tab background, when tab-bar is unfocused & tab is unselected
        TabDimmedSelected = 39, /// Tab background, when tab-bar is unfocused & tab is selected
        TabDimmedSelectedOverline = 40, //..horizontal overline, when tab-bar is unfocused & tab is selected
        DockingPreview = 41, /// Preview overlay color when about to docking something
        DockingEmptyBg = 42, /// Background color for empty node (e.g. CentralNode with no window docked into it)
        PlotLines = 43,
        PlotLinesHovered = 44,
        PlotHistogram = 45,
        PlotHistogramHovered = 46,
        TableHeaderBg = 47, /// Table header background
        TableBorderStrong = 48, /// Table outer and header borders (prefer using Alpha=1.0 here)
        TableBorderLight = 49, /// Table inner borders (prefer using Alpha=1.0 here)
        TableRowBg = 50, /// Table row background (even rows)
        TableRowBgAlt = 51, /// Table row background (odd rows)
        TextLink = 52, /// Hyperlink color
        TextSelectedBg = 53, /// Selected text inside an InputText
        TreeLines = 54, /// Tree node hierarchy outlines when using ImGuiTreeNodeFlags_DrawLines
        DragDropTarget = 55, /// Rectangle highlighting a drop target
        NavCursor = 56, /// Color of keyboard/gamepad navigation cursor/rectangle, when visible
        NavWindowingHighlight = 57, /// Highlight window when using CTRL+TAB
        NavWindowingDimBg = 58, /// Darken/colorize entire screen behind the CTRL+TAB window list, when active
        ModalWindowDimBg = 59, /// Darken/colorize entire screen behind a modal window, when one is active
        COUNT = 60,
    }

    /// Flags for InvisibleButton() [extended in imgui_internal.h]
    enum ImGuiButtonFlags {
        None = 0,
        MouseButtonLeft = 1, /// React on left mouse button (default)
        MouseButtonRight = 2, /// React on right mouse button
        MouseButtonMiddle = 4, /// React on center mouse button
        MouseButtonMask_ = 7, /// [Internal]
        EnableNav = 8, /// InvisibleButton(): do not disable navigation/tabbing. Otherwise disabled by default.
    }

    /// Flags stored in ImGuiViewport::Flags, giving indications to the platform backends.
    enum ImGuiViewportFlags {
        None = 0,
        IsPlatformWindow = 1, /// Represent a Platform Window
        IsPlatformMonitor = 2, /// Represent a Platform Monitor (unused yet)
        OwnedByApp = 4, /// Platform Window: Is created/managed by the user application? (rather than our backend)
        NoDecoration = 8, /// Platform Window: Disable platform decorations: title bar, borders, etc. (generally set all windows, but if ImGuiConfigFlags_ViewportsDecoration is set we only set this on popups/tooltips)
        NoTaskBarIcon = 16, /// Platform Window: Disable platform task bar icon (generally set on popups/tooltips, or all windows if ImGuiConfigFlags_ViewportsNoTaskBarIcon is set)
        NoFocusOnAppearing = 32, /// Platform Window: Don't take focus when created.
        NoFocusOnClick = 64, /// Platform Window: Don't take focus when clicked on.
        NoInputs = 128, /// Platform Window: Make mouse pass through so we can drag this window while peaking behind it.
        NoRendererClear = 256, /// Platform Window: Renderer doesn't need to clear the framebuffer ahead (because we will fill it entirely).
        NoAutoMerge = 512, /// Platform Window: Avoid merging this window into another host window. This can only be set via ImGuiWindowClass viewport flags override (because we need to now ahead if we are going to create a viewport in the first place!).
        TopMost = 1024, /// Platform Window: Display on top (for tooltips only).
        CanHostOtherWindows = 2048, /// Viewport can host multiple imgui windows (secondary viewports are associated to a single window). /// FIXME: In practice there's still probably code making the assumption that this is always and only on the MainViewport. Will fix once we add support for "no main viewport".
        IsMinimized = 4096, /// Platform Window: Window is minimized, can skip render. When minimized we tend to avoid using the viewport pos/size for clipping window or testing if they are contained in the viewport.
        IsFocused = 8192, /// Platform Window: Window is focused (last call to Platform_GetWindowFocus() returned true)
    }

    /// Extend ImGuiSelectableFlags_
    enum ImGuiSelectableFlagsI : ImGuiSelectableFlags {
        NoHoldingActiveID = cast(ImGuiSelectableFlags)1048576,
        SelectOnNav = cast(ImGuiSelectableFlags)2097152, /// (WIP) Auto-select when moved into. This is not exposed in public API as to handle multi-select and modifiers we will need user to explicitly control focus scope. May be replaced with a BeginSelection() API.
        SelectOnClick = cast(ImGuiSelectableFlags)4194304, /// Override button behavior to react on Click (default is Click+Release)
        SelectOnRelease = cast(ImGuiSelectableFlags)8388608, /// Override button behavior to react on Release (default is Click+Release)
        SpanAvailWidth = cast(ImGuiSelectableFlags)16777216, /// Span all avail width even if we declared less for layout purpose. FIXME: We may be able to remove this (added in 6251d379, 2bcafc86 for menus)
        SetNavIdOnHover = cast(ImGuiSelectableFlags)33554432, /// Set Nav/Focus ID on mouse hover (used by MenuItem)
        NoPadWithHalfSpacing = cast(ImGuiSelectableFlags)67108864, /// Disable padding each side with ItemSpacing * 0.5f
        NoSetKeyOwner = cast(ImGuiSelectableFlags)134217728, /// Don't set key/input owner on the initial click (note: mouse buttons are keys! often, the key in question will be ImGuiKey_MouseLeft!)
    }

    enum ImGuiInputSource {
        None = 0,
        Mouse = 1, /// Note: may be Mouse or TouchScreen or Pen. See io.MouseSource to distinguish them.
        Keyboard = 2,
        Gamepad = 3,
        COUNT = 4,
    }

    /// Enumeration for GetMouseCursor()
    /// User code may request backend to display given cursor by calling SetMouseCursor(), which is why we have some cursors that are marked unused here
    enum ImGuiMouseCursor {
        None = -1,
        Arrow = 0,
        TextInput = 1, /// When hovering over InputText, etc.
        ResizeAll = 2, /// (Unused by Dear ImGui functions)
        ResizeNS = 3, /// When hovering over a horizontal border
        ResizeEW = 4, /// When hovering over a vertical border or a column
        ResizeNESW = 5, /// When hovering over the bottom-left corner of a window
        ResizeNWSE = 6, /// When hovering over the bottom-right corner of a window
        Hand = 7, /// (Unused by Dear ImGui functions. Use for e.g. hyperlinks)
        Wait = 8, /// When waiting for something to process/load.
        Progress = 9, /// When waiting for something to process/load, but application is still interactive.
        NotAllowed = 10, /// When hovering something with disallowed interaction. Usually a crossed circle.
        COUNT = 11,
    }

    /// Flags for BeginMultiSelect()
    enum ImGuiMultiSelectFlags {
        None = 0,
        SingleSelect = 1, /// Disable selecting more than one item. This is available to allow single-selection code to share same code/logic if desired. It essentially disables the main purpose of BeginMultiSelect() tho!
        NoSelectAll = 2, /// Disable CTRL+A shortcut to select all.
        NoRangeSelect = 4, /// Disable Shift+selection mouse/keyboard support (useful for unordered 2D selection). With BoxSelect is also ensure contiguous SetRange requests are not combined into one. This allows not handling interpolation in SetRange requests.
        NoAutoSelect = 8, /// Disable selecting items when navigating (useful for e.g. supporting range-select in a list of checkboxes).
        NoAutoClear = 16, /// Disable clearing selection when navigating or selecting another one (generally used with ImGuiMultiSelectFlags_NoAutoSelect. useful for e.g. supporting range-select in a list of checkboxes).
        NoAutoClearOnReselect = 32, /// Disable clearing selection when clicking/selecting an already selected item.
        BoxSelect1d = 64, /// Enable box-selection with same width and same x pos items (e.g. full row Selectable()). Box-selection works better with little bit of spacing between items hit-box in order to be able to aim at empty space.
        BoxSelect2d = 128, /// Enable box-selection with varying width or varying x pos items support (e.g. different width labels, or 2D layout/grid). This is slower: alters clipping logic so that e.g. horizontal movements will update selection of normally clipped items.
        BoxSelectNoScroll = 256, /// Disable scrolling when box-selecting near edges of scope.
        ClearOnEscape = 512, /// Clear selection when pressing Escape while scope is focused.
        ClearOnClickVoid = 1024, /// Clear selection when clicking on empty location within scope.
        ScopeWindow = 2048, /// Scope for _BoxSelect and _ClearOnClickVoid is whole window (Default). Use if BeginMultiSelect() covers a whole window or used a single time in same window.
        ScopeRect = 4096, /// Scope for _BoxSelect and _ClearOnClickVoid is rectangle encompassing BeginMultiSelect()/EndMultiSelect(). Use if BeginMultiSelect() is called multiple times in same window.
        SelectOnClick = 8192, /// Apply selection on mouse down when clicking on unselected item. (Default)
        SelectOnClickRelease = 16384, /// Apply selection on mouse release when clicking an unselected item. Allow dragging an unselected item without altering selection.
        NavWrapX = 65536, /// [Temporary] Enable navigation wrapping on X axis. Provided as a convenience because we don't have a design for the general Nav API for this yet. When the more general feature be public we may obsolete this flag in favor of new one.
    }

    enum ImGuiDockRequestType {
        None = 0,
        Dock = 1,
        Undock = 2,
        Split = 3, /// Split is the same as Dock but without a DockPayload
    }

    /// Flags for ImGui::DockSpace(), shared/inherited by child nodes.
    /// (Some flags can be applied to individual nodes directly)
    /// FIXME-DOCK: Also see ImGuiDockNodeFlagsPrivate_ which may involve using the WIP and internal DockBuilder api.
    enum ImGuiDockNodeFlags {
        None = 0,
        KeepAliveOnly = 1, ///       /// Don't display the dockspace node but keep it alive. Windows docked into this dockspace node won't be undocked.
        NoDockingOverCentralNode = 4, ///       /// Disable docking over the Central Node, which will be always kept empty.
        PassthruCentralNode = 8, ///       /// Enable passthru dockspace: 1) DockSpace() will render a ImGuiCol_WindowBg background covering everything excepted the Central Node when empty. Meaning the host window should probably use SetNextWindowBgAlpha(0.0f) prior to Begin() when using this. 2) When Central Node is empty: let inputs pass-through + won't display a DockingEmptyBg background. See demo for details.
        NoDockingSplit = 16, ///       /// Disable other windows/nodes from splitting this node.
        NoResize = 32, /// Saved /// Disable resizing node using the splitter/separators. Useful with programmatically setup dockspaces.
        AutoHideTabBar = 64, ///       /// Tab bar will automatically hide when there is a single window in the dock node.
        NoUndocking = 128, ///       /// Disable undocking this node.
    }

    /// Flags for ImGui::InputText()
    /// (Those are per-item flags. There are shared flags in ImGuiIO: io.ConfigInputTextCursorBlink and io.ConfigInputTextEnterKeepActive)
    enum ImGuiInputTextFlags {
        None = 0,
        CharsDecimal = 1, /// Allow 0123456789.+-*/
        CharsHexadecimal = 2, /// Allow 0123456789ABCDEFabcdef
        CharsScientific = 4, /// Allow 0123456789.+-*/eE (Scientific notation input)
        CharsUppercase = 8, /// Turn a..z into A..Z
        CharsNoBlank = 16, /// Filter out spaces, tabs
        AllowTabInput = 32, /// Pressing TAB input a '\t' character into the text field
        EnterReturnsTrue = 64, /// Return 'true' when Enter is pressed (as opposed to every time the value was modified). Consider using IsItemDeactivatedAfterEdit() instead!
        EscapeClearsAll = 128, /// Escape key clears content if not empty, and deactivate otherwise (contrast to default behavior of Escape to revert)
        CtrlEnterForNewLine = 256, /// In multi-line mode, validate with Enter, add new line with Ctrl+Enter (default is opposite: validate with Ctrl+Enter, add line with Enter).
        ReadOnly = 512, /// Read-only mode
        Password = 1024, /// Password mode, display all characters as '*', disable copy
        AlwaysOverwrite = 2048, /// Overwrite mode
        AutoSelectAll = 4096, /// Select entire text when first taking mouse focus
        ParseEmptyRefVal = 8192, /// InputFloat(), InputInt(), InputScalar() etc. only: parse empty string as zero value.
        DisplayEmptyRefVal = 16384, /// InputFloat(), InputInt(), InputScalar() etc. only: when value is zero, do not display it. Generally used with ImGuiInputTextFlags_ParseEmptyRefVal.
        NoHorizontalScroll = 32768, /// Disable following the cursor horizontally
        NoUndoRedo = 65536, /// Disable undo/redo. Note that input text owns the text data while active, if you want to provide your own undo/redo stack you need e.g. to call ClearActiveID().
        ElideLeft = 131072, /// When text doesn't fit, elide left side to ensure right side stays visible. Useful for path/filenames. Single-line only!
        CallbackCompletion = 262144, /// Callback on pressing TAB (for completion handling)
        CallbackHistory = 524288, /// Callback on pressing Up/Down arrows (for history handling)
        CallbackAlways = 1048576, /// Callback on each iteration. User code may query cursor position, modify text buffer.
        CallbackCharFilter = 2097152, /// Callback on character inputs to replace or discard them. Modify 'EventChar' to replace or discard, or return 1 in callback to discard.
        CallbackResize = 4194304, /// Callback on buffer capacity changes request (beyond 'buf_size' parameter value), allowing the string to grow. Notify when the string wants to be resized (for string types which hold a cache of their Size). You will be provided a new BufSize in the callback and NEED to honor it. (see misc/cpp/imgui_stdlib.h for an example of using this)
        CallbackEdit = 8388608, /// Callback on any edit. Note that InputText() already returns true on edit + you can always use IsItemEdited(). The callback is useful to manipulate the underlying buffer while focus is active.
    }

    /// Flags for OpenPopup*(), BeginPopupContext*(), IsPopupOpen() functions.
    /// - To be backward compatible with older API which took an 'int mouse_button = 1' argument instead of 'ImGuiPopupFlags flags',
    ///   we need to treat small flags values as a mouse button index, so we encode the mouse button in the first few bits of the flags.
    ///   It is therefore guaranteed to be legal to pass a mouse button index in ImGuiPopupFlags.
    /// - For the same reason, we exceptionally default the ImGuiPopupFlags argument of BeginPopupContextXXX functions to 1 instead of 0.
    ///   IMPORTANT: because the default parameter is 1 (==ImGuiPopupFlags_MouseButtonRight), if you rely on the default parameter
    ///   and want to use another flag, you need to pass in the ImGuiPopupFlags_MouseButtonRight flag explicitly.
    /// - Multiple buttons currently cannot be combined/or-ed in those functions (we could allow it later).
    enum ImGuiPopupFlags {
        None = 0,
        MouseButtonLeft = 0, /// For BeginPopupContext*(): open on Left Mouse release. Guaranteed to always be == 0 (same as ImGuiMouseButton_Left)
        MouseButtonRight = 1, /// For BeginPopupContext*(): open on Right Mouse release. Guaranteed to always be == 1 (same as ImGuiMouseButton_Right)
        MouseButtonMiddle = 2, /// For BeginPopupContext*(): open on Middle Mouse release. Guaranteed to always be == 2 (same as ImGuiMouseButton_Middle)
        MouseButtonMask_ = 31,
        MouseButtonDefault_ = 1,
        NoReopen = 32, /// For OpenPopup*(), BeginPopupContext*(): don't reopen same popup if already open (won't reposition, won't reinitialize navigation)
        NoOpenOverExistingPopup = 128, /// For OpenPopup*(), BeginPopupContext*(): don't open if there's already a popup at the same level of the popup stack
        NoOpenOverItems = 256, /// For BeginPopupContextWindow(): don't return true when hovering items, only when hovering empty space
        AnyPopupId = 1024, /// For IsPopupOpen(): ignore the ImGuiID parameter and test for any popup.
        AnyPopupLevel = 2048, /// For IsPopupOpen(): search/test at any level of the popup stack (default test in the current level)
        AnyPopup = 3072,
    }

    /// Font flags
    /// (in future versions as we redesign font loading API, this will become more important and better documented. for now please consider this as internal/advanced use)
    enum ImFontFlags {
        None = 0,
        DefaultToLegacySize = 1, /// Legacy compatibility: make PushFont() calls without explicit size use font->LegacySize instead of current font size.
        NoLoadError = 2, /// Disable throwing an error/assert when calling AddFontXXX() with missing file/data. Calling code is expected to check AddFontXXX() return value.
        NoLoadGlyphs = 4, /// [Internal] Disable loading new glyphs.
        LockBakedSizes = 8, /// [Internal] Disable loading new baked sizes, disable garbage collecting current ones. e.g. if you want to lock a font to a single size. Important: if you use this to preload given sizes, consider the possibility of multiple font density used on Retina display.
    }

    enum ImGuiActivateFlags {
        None = 0,
        PreferInput = 1, /// Favor activation that requires keyboard text input (e.g. for Slider/Drag). Default for Enter key.
        PreferTweak = 2, /// Favor activation for tweaking with arrows or gamepad (e.g. for Slider/Drag). Default for Space key and if keyboard is not used.
        TryToPreserveState = 4, /// Request widget to preserve state if it can (e.g. InputText will try to preserve cursor/selection)
        FromTabbing = 8, /// Activation requested by a tabbing request
        FromShortcut = 16, /// Activation requested by an item shortcut via SetNextItemShortcut() function.
    }

    /// Flags for ImGui::IsItemHovered(), ImGui::IsWindowHovered()
    /// Note: if you are trying to check whether your mouse should be dispatched to Dear ImGui or to your app, you should use 'io.WantCaptureMouse' instead! Please read the FAQ!
    /// Note: windows with the ImGuiWindowFlags_NoInputs flag are ignored by IsWindowHovered() calls.
    enum ImGuiHoveredFlags {
        None = 0, /// Return true if directly over the item/window, not obstructed by another window, not obstructed by an active popup or modal blocking inputs under them.
        ChildWindows = 1, /// IsWindowHovered() only: Return true if any children of the window is hovered
        RootWindow = 2, /// IsWindowHovered() only: Test from root window (top most parent of the current hierarchy)
        AnyWindow = 4, /// IsWindowHovered() only: Return true if any window is hovered
        NoPopupHierarchy = 8, /// IsWindowHovered() only: Do not consider popup hierarchy (do not treat popup emitter as parent of popup) (when used with _ChildWindows or _RootWindow)
        DockHierarchy = 16, /// IsWindowHovered() only: Consider docking hierarchy (treat dockspace host as parent of docked window) (when used with _ChildWindows or _RootWindow)
        AllowWhenBlockedByPopup = 32, /// Return true even if a popup window is normally blocking access to this item/window
        AllowWhenBlockedByActiveItem = 128, /// Return true even if an active item is blocking access to this item/window. Useful for Drag and Drop patterns.
        AllowWhenOverlappedByItem = 256, /// IsItemHovered() only: Return true even if the item uses AllowOverlap mode and is overlapped by another hoverable item.
        AllowWhenOverlappedByWindow = 512, /// IsItemHovered() only: Return true even if the position is obstructed or overlapped by another window.
        AllowWhenDisabled = 1024, /// IsItemHovered() only: Return true even if the item is disabled
        NoNavOverride = 2048, /// IsItemHovered() only: Disable using keyboard/gamepad navigation state when active, always query mouse
        AllowWhenOverlapped = 768,
        RectOnly = 928,
        RootAndChildWindows = 3,
        ForTooltip = 4096, /// Shortcut for standard flags when using IsItemHovered() + SetTooltip() sequence.
        Stationary = 8192, /// Require mouse to be stationary for style.HoverStationaryDelay (~0.15 sec) _at least one time_. After this, can move on same item/window. Using the stationary test tends to reduces the need for a long delay.
        DelayNone = 16384, /// IsItemHovered() only: Return true immediately (default). As this is the default you generally ignore this.
        DelayShort = 32768, /// IsItemHovered() only: Return true after style.HoverDelayShort elapsed (~0.15 sec) (shared between items) + requires mouse to be stationary for style.HoverStationaryDelay (once per item).
        DelayNormal = 65536, /// IsItemHovered() only: Return true after style.HoverDelayNormal elapsed (~0.40 sec) (shared between items) + requires mouse to be stationary for style.HoverStationaryDelay (once per item).
        NoSharedDelay = 131072, /// IsItemHovered() only: Disable shared delay system where moving from one item to the next keeps the previous timer for a short time (standard for tooltips with long delays)
    }


    struct ImGuiInputEventText {
        uint Char;
    }

    struct ImGuiStackLevelInfo {
        ImGuiID ID;
        ImS8 QueryFrameCount; /// >= 1: Query in progress
        bool QuerySuccess; /// Obtained result from DebugHookIdInfo()
        ImGuiDataType DataType;
        char[57] Desc; /// Arbitrarily sized buffer to hold a result (FIXME: could replace Results[] with a chunk stream?) FIXME: Now that we added CTRL+C this should be fixed.
    }

    /// Data saved for each window pushed into the stack
    struct ImGuiWindowStackData {
        ImGuiWindow* Window;
        ImGuiLastItemData ParentLastItemDataBackup;
        ImGuiErrorRecoveryState StackSizesInBegin; /// Store size of various stacks for asserting
        bool DisabledOverrideReenable; /// Non-child window override disabled flag
        float DisabledOverrideReenableAlphaBackup;
    }

    /// Routing table entry (sizeof() == 16 bytes)
    struct ImGuiKeyRoutingData {
        ImGuiKeyRoutingIndex NextEntryIndex;
        ImU16 Mods; /// Technically we'd only need 4-bits but for simplify we store ImGuiMod_ values which need 16-bits.
        ImU8 RoutingCurrScore; /// [DEBUG] For debug display
        ImU8 RoutingNextScore; /// Lower is better (0: perfect score)
        ImGuiID RoutingCurr;
        ImGuiID RoutingNext;
    }

    /// Transient data that are only needed between BeginTable() and EndTable(), those buffers are shared (1 per level of stacked table).
    /// - Accessing those requires chasing an extra pointer so for very frequently used data we leave them in the main table structure.
    /// - We also leave out of this structure data that tend to be particularly useful for debugging/metrics.
    /// FIXME-TABLE: more transient data could be stored in a stacked ImGuiTableTempData: e.g. SortSpecs.
    /// sizeof() ~ 136 bytes.
    struct ImGuiTableTempData {
        int TableIndex; /// Index in g.Tables.Buf[] pool
        float LastTimeActive; /// Last timestamp this structure was used
        float AngledHeadersExtraWidth; /// Used in EndTable()
        ImVector!(ImGuiTableHeaderData) AngledHeadersRequests; /// Used in TableAngledHeadersRow()
        ImVec2 UserOuterSize; /// outer_size.x passed to BeginTable()
        ImDrawListSplitter DrawSplitter;
        ImRect HostBackupWorkRect; /// Backup of InnerWindow->WorkRect at the end of BeginTable()
        ImRect HostBackupParentWorkRect; /// Backup of InnerWindow->ParentWorkRect at the end of BeginTable()
        ImVec2 HostBackupPrevLineSize; /// Backup of InnerWindow->DC.PrevLineSize at the end of BeginTable()
        ImVec2 HostBackupCurrLineSize; /// Backup of InnerWindow->DC.CurrLineSize at the end of BeginTable()
        ImVec2 HostBackupCursorMaxPos; /// Backup of InnerWindow->DC.CursorMaxPos at the end of BeginTable()
        ImVec1 HostBackupColumnsOffset; /// Backup of OuterWindow->DC.ColumnsOffset at the end of BeginTable()
        float HostBackupItemWidth; /// Backup of OuterWindow->DC.ItemWidth at the end of BeginTable()
        int HostBackupItemWidthStackSize; //Backup of OuterWindow->DC.ItemWidthStack.Size at the end of BeginTable()
    }

    /// Type information associated to one ImGuiDataType. Retrieve with DataTypeGetInfo().
    struct ImGuiDataTypeInfo {
        size_t Size; /// Size in bytes
        const(char)* Name; /// Short descriptive name for the type, for debugging
        const(char)* PrintFmt; /// Default printf format for the type
        const(char)* ScanFmt; /// Default scanf format for the type
    }

    /// Storage for popup stacks (g.OpenPopupStack and g.BeginPopupStack)
    struct ImGuiPopupData {
        ImGuiID PopupId; /// Set on OpenPopup()
        ImGuiWindow* Window; /// Resolved on BeginPopup() - may stay unresolved if user never calls OpenPopup()
        ImGuiWindow* RestoreNavWindow; /// Set on OpenPopup(), a NavWindow that will be restored on popup close
        int ParentNavLayer; /// Resolved on BeginPopup(). Actually a ImGuiNavLayer type (declared down below), initialized to -1 which is not part of an enum, but serves well-enough as "not any of layers" value
        int OpenFrameCount; /// Set on OpenPopup()
        ImGuiID OpenParentId; /// Set on OpenPopup(), we need this to differentiate multiple menu sets from each others (e.g. inside menu bar vs loose menu items)
        ImVec2 OpenPopupPos; /// Set on OpenPopup(), preferred popup position (typically == OpenMousePos when using mouse)
        ImVec2 OpenMousePos; /// Set on OpenPopup(), copy of mouse position at the time of opening popup
    }

    /// Storage for one window
    struct ImGuiWindow {
        ImGuiContext* Ctx; /// Parent UI context (needs to be set explicitly by parent).
        char* Name; /// Window name, owned by the window.
        ImGuiID ID; /// == ImHashStr(Name)
        ImGuiWindowFlags Flags; /// See enum ImGuiWindowFlags_
        ImGuiWindowFlags FlagsPreviousFrame; /// See enum ImGuiWindowFlags_
        ImGuiChildFlags ChildFlags; /// Set when window is a child window. See enum ImGuiChildFlags_
        ImGuiWindowClass WindowClass; /// Advanced users only. Set with SetNextWindowClass()
        ImGuiViewportP* Viewport; /// Always set in Begin(). Inactive windows may have a NULL value here if their viewport was discarded.
        ImGuiID ViewportId; /// We backup the viewport id (since the viewport may disappear or never be created if the window is inactive)
        ImVec2 ViewportPos; /// We backup the viewport position (since the viewport may disappear or never be created if the window is inactive)
        int ViewportAllowPlatformMonitorExtend; /// Reset to -1 every frame (index is guaranteed to be valid between NewFrame..EndFrame), only used in the Appearing frame of a tooltip/popup to enforce clamping to a given monitor
        ImVec2 Pos; /// Position (always rounded-up to nearest pixel)
        ImVec2 Size; /// Current size (==SizeFull or collapsed title bar size)
        ImVec2 SizeFull; /// Size when non collapsed
        ImVec2 ContentSize; /// Size of contents/scrollable client area (calculated from the extents reach of the cursor) from previous frame. Does not include window decoration or window padding.
        ImVec2 ContentSizeIdeal;
        ImVec2 ContentSizeExplicit; /// Size of contents/scrollable client area explicitly request by the user via SetNextWindowContentSize().
        ImVec2 WindowPadding; /// Window padding at the time of Begin().
        float WindowRounding; /// Window rounding at the time of Begin(). May be clamped lower to avoid rendering artifacts with title bar, menu bar etc.
        float WindowBorderSize; /// Window border size at the time of Begin().
        float TitleBarHeight; /// Note that those used to be function before 2024/05/28. If you have old code calling TitleBarHeight() you can change it to TitleBarHeight.
        float MenuBarHeight; /// Note that those used to be function before 2024/05/28. If you have old code calling TitleBarHeight() you can change it to TitleBarHeight.
        float DecoOuterSizeX1; /// Left/Up offsets. Sum of non-scrolling outer decorations (X1 generally == 0.0f. Y1 generally = TitleBarHeight + MenuBarHeight). Locked during Begin().
        float DecoOuterSizeY1; /// Left/Up offsets. Sum of non-scrolling outer decorations (X1 generally == 0.0f. Y1 generally = TitleBarHeight + MenuBarHeight). Locked during Begin().
        float DecoOuterSizeX2; /// Right/Down offsets (X2 generally == ScrollbarSize.x, Y2 == ScrollbarSizes.y).
        float DecoOuterSizeY2; /// Right/Down offsets (X2 generally == ScrollbarSize.x, Y2 == ScrollbarSizes.y).
        float DecoInnerSizeX1; /// Applied AFTER/OVER InnerRect. Specialized for Tables as they use specialized form of clipping and frozen rows/columns are inside InnerRect (and not part of regular decoration sizes).
        float DecoInnerSizeY1; /// Applied AFTER/OVER InnerRect. Specialized for Tables as they use specialized form of clipping and frozen rows/columns are inside InnerRect (and not part of regular decoration sizes).
        int NameBufLen; /// Size of buffer storing Name. May be larger than strlen(Name)!
        ImGuiID MoveId; /// == window->GetID("#MOVE")
        ImGuiID TabId; /// == window->GetID("#TAB")
        ImGuiID ChildId; /// ID of corresponding item in parent window (for navigation to return from child window to parent window)
        ImGuiID PopupId; /// ID in the popup stack when this window is used as a popup/menu (because we use generic Name/ID for recycling)
        ImVec2 Scroll;
        ImVec2 ScrollMax;
        ImVec2 ScrollTarget; /// target scroll position. stored as cursor position with scrolling canceled out, so the highest point is always 0.0f. (FLT_MAX for no change)
        ImVec2 ScrollTargetCenterRatio; /// 0.0f = scroll so that target position is at top, 0.5f = scroll so that target position is centered
        ImVec2 ScrollTargetEdgeSnapDist; /// 0.0f = no snapping, >0.0f snapping threshold
        ImVec2 ScrollbarSizes; /// Size taken by each scrollbars on their smaller axis. Pay attention! ScrollbarSizes.x == width of the vertical scrollbar, ScrollbarSizes.y = height of the horizontal scrollbar.
        bool ScrollbarX; /// Are scrollbars visible?
        bool ScrollbarY; /// Are scrollbars visible?
        bool ScrollbarXStabilizeEnabled; /// Was ScrollbarX previously auto-stabilized?
        ImU8 ScrollbarXStabilizeToggledHistory; /// Used to stabilize scrollbar visibility in case of feedback loops
        bool ViewportOwned;
        bool Active; /// Set to true on Begin(), unless Collapsed
        bool WasActive;
        bool WriteAccessed; /// Set to true when any widget access the current window
        bool Collapsed; /// Set when collapsing window to become only title-bar
        bool WantCollapseToggle;
        bool SkipItems; /// Set when items can safely be all clipped (e.g. window not visible or collapsed)
        bool SkipRefresh; /// [EXPERIMENTAL] Reuse previous frame drawn contents, Begin() returns false.
        bool Appearing; /// Set during the frame where the window is appearing (or re-appearing)
        bool Hidden; /// Do not display (== HiddenFrames*** > 0)
        bool IsFallbackWindow; /// Set on the "Debug##Default" window.
        bool IsExplicitChild; /// Set when passed _ChildWindow, left to false by BeginDocked()
        bool HasCloseButton; /// Set when the window has a close button (p_open != NULL)
        byte ResizeBorderHovered; /// Current border being hovered for resize (-1: none, otherwise 0-3)
        byte ResizeBorderHeld; /// Current border being held for resize (-1: none, otherwise 0-3)
        short BeginCount; /// Number of Begin() during the current frame (generally 0 or 1, 1+ if appending via multiple Begin/End pairs)
        short BeginCountPreviousFrame; /// Number of Begin() during the previous frame
        short BeginOrderWithinParent; /// Begin() order within immediate parent window, if we are a child window. Otherwise 0.
        short BeginOrderWithinContext; /// Begin() order within entire imgui context. This is mostly used for debugging submission order related issues.
        short FocusOrder; /// Order within WindowsFocusOrder[], altered when windows are focused.
        ImS8 AutoFitFramesX;
        ImS8 AutoFitFramesY;
        bool AutoFitOnlyGrows;
        ImGuiDir AutoPosLastDirection;
        ImS8 HiddenFramesCanSkipItems; /// Hide the window for N frames
        ImS8 HiddenFramesCannotSkipItems; /// Hide the window for N frames while allowing items to be submitted so we can measure their size
        ImS8 HiddenFramesForRenderOnly; /// Hide the window until frame N at Render() time only
        ImS8 DisableInputsFrames; /// Disable window interactions for N frames
        ImGuiCond SetWindowPosAllowFlags; /// store acceptable condition flags for SetNextWindowPos() use.
        ImGuiCond SetWindowSizeAllowFlags; /// store acceptable condition flags for SetNextWindowSize() use.
        ImGuiCond SetWindowCollapsedAllowFlags; /// store acceptable condition flags for SetNextWindowCollapsed() use.
        ImGuiCond SetWindowDockAllowFlags; /// store acceptable condition flags for SetNextWindowDock() use.
        ImVec2 SetWindowPosVal; /// store window position when using a non-zero Pivot (position set needs to be processed when we know the window size)
        ImVec2 SetWindowPosPivot; /// store window pivot for positioning. ImVec2(0, 0) when positioning from top-left corner; ImVec2(0.5f, 0.5f) for centering; ImVec2(1, 1) for bottom right.
        ImVector!(ImGuiID) IDStack; /// ID stack. ID are hashes seeded with the value at the top of the stack. (In theory this should be in the TempData structure)
        ImGuiWindowTempData DC; /// Temporary per-window data, reset at the beginning of the frame. This used to be called ImGuiDrawContext, hence the "DC" variable name.
             /// The best way to understand what those rectangles are is to use the 'Metrics->Tools->Show Windows Rectangles' viewer.
            /// The main 'OuterRect', omitted as a field, is window->Rect().
        ImRect OuterRectClipped; /// == Window->Rect() just after setup in Begin(). == window->Rect() for root window.
        ImRect InnerRect; /// Inner rectangle (omit title bar, menu bar, scroll bar)
        ImRect InnerClipRect; /// == InnerRect shrunk by WindowPadding*0.5f on each side, clipped within viewport or parent clip rect.
        ImRect WorkRect; /// Initially covers the whole scrolling region. Reduced by containers e.g columns/tables when active. Shrunk by WindowPadding*1.0f on each side. This is meant to replace ContentRegionRect over time (from 1.71+ onward).
        ImRect ParentWorkRect; /// Backup of WorkRect before entering a container such as columns/tables. Used by e.g. SpanAllColumns functions to easily access. Stacked containers are responsible for maintaining this. /// FIXME-WORKRECT: Could be a stack?
        ImRect ClipRect; /// Current clipping/scissoring rectangle, evolve as we are using PushClipRect(), etc. == DrawList->clip_rect_stack.back().
        ImRect ContentRegionRect; /// FIXME: This is currently confusing/misleading. It is essentially WorkRect but not handling of scrolling. We currently rely on it as right/bottom aligned sizing operation need some size to rely on.
        ImVec2ih HitTestHoleSize; /// Define an optional rectangular hole where mouse will pass-through the window.
        ImVec2ih HitTestHoleOffset;
        int LastFrameActive; /// Last frame number the window was Active.
        int LastFrameJustFocused; /// Last frame number the window was made Focused.
        float LastTimeActive; /// Last timestamp the window was Active (using float as we don't need high precision there)
        float ItemWidthDefault;
        ImGuiStorage StateStorage;
        ImVector!(ImGuiOldColumns) ColumnsStorage;
        float FontWindowScale; /// User scale multiplier per-window, via SetWindowFontScale()
        float FontWindowScaleParents;
        float FontRefSize; /// This is a copy of window->CalcFontSize() at the time of Begin(), trying to phase out CalcFontSize() especially as it may be called on non-current window.
        int SettingsOffset; /// Offset into SettingsWindows[] (offsets are always valid as we only grow the array from the back)
        ImDrawList* DrawList; /// == &DrawListInst (for backward compatibility reason with code using imgui_internal.h we keep this a pointer)
        ImDrawList DrawListInst;
        ImGuiWindow* ParentWindow; /// If we are a child _or_ popup _or_ docked window, this is pointing to our parent. Otherwise NULL.
        ImGuiWindow* ParentWindowInBeginStack;
        ImGuiWindow* RootWindow; /// Point to ourself or first ancestor that is not a child window. Doesn't cross through popups/dock nodes.
        ImGuiWindow* RootWindowPopupTree; /// Point to ourself or first ancestor that is not a child window. Cross through popups parent<>child.
        ImGuiWindow* RootWindowDockTree; /// Point to ourself or first ancestor that is not a child window. Cross through dock nodes.
        ImGuiWindow* RootWindowForTitleBarHighlight; /// Point to ourself or first ancestor which will display TitleBgActive color when this window is active.
        ImGuiWindow* RootWindowForNav; /// Point to ourself or first ancestor which doesn't have the NavFlattened flag.
        ImGuiWindow* ParentWindowForFocusRoute; /// Set to manual link a window to its logical parent so that Shortcut() chain are honoerd (e.g. Tool linked to Document)
        ImGuiWindow* NavLastChildNavWindow; /// When going to the menu bar, we remember the child window we came from. (This could probably be made implicit if we kept g.Windows sorted by last focused including child window.)
        ImGuiID[ImGuiNavLayer.COUNT] NavLastIds; /// Last known NavId for this window, per layer (0/1)
        ImRect[ImGuiNavLayer.COUNT] NavRectRel; /// Reference rectangle, in window relative space
        ImVec2[ImGuiNavLayer.COUNT] NavPreferredScoringPosRel; /// Preferred X/Y position updated when moving on a given axis, reset to FLT_MAX.
        ImGuiID NavRootFocusScopeId; /// Focus Scope ID at the time of Begin()
        int MemoryDrawListIdxCapacity; /// Backup of last idx/vtx count, so when waking up the window we can preallocate and avoid iterative alloc/copy
        int MemoryDrawListVtxCapacity;
        bool MemoryCompacted; /// Set when window extraneous data have been garbage collected
             /// Docking
        bool DockIsActive; /// When docking artifacts are actually visible. When this is set, DockNode is guaranteed to be != NULL. ~~ (DockNode != NULL) && (DockNode->Windows.Size > 1).
        bool DockNodeIsVisible;
        bool DockTabIsVisible; /// Is our window visible this frame? ~~ is the corresponding tab selected?
        bool DockTabWantClose;
        short DockOrder; /// Order of the last time the window was visible within its DockNode. This is used to reorder windows that are reappearing on the same frame. Same value between windows that were active and windows that were none are possible.
        ImGuiWindowDockStyle DockStyle;
        ImGuiDockNode* DockNode; /// Which node are we docked into. Important: Prefer testing DockIsActive in many cases as this will still be set when the dock node is hidden.
        ImGuiDockNode* DockNodeAsHost; /// Which node are we owning (for parent windows)
        ImGuiID DockId; /// Backup of last valid DockNode->ID, so single window remember their dock node id even when they are not bound any more
    }

    /// Routing table: maintain a desired owner for each possible key-chord (key + mods), and setup owner in NewFrame() when mods are matching.
    /// Stored in main context (1 instance)
    struct ImGuiKeyRoutingTable {
        ImGuiKeyRoutingIndex[ImGuiKey.NamedKey_COUNT] Index; /// Index of first entry in Entries[]
        ImVector!(ImGuiKeyRoutingData) Entries;
        ImVector!(ImGuiKeyRoutingData) EntriesNext; /// Double-buffer to avoid reallocation (could use a shared buffer)
    }

    /// sizeof() = 20
    struct ImGuiErrorRecoveryState {
        short SizeOfWindowStack;
        short SizeOfIDStack;
        short SizeOfTreeStack;
        short SizeOfColorStack;
        short SizeOfStyleVarStack;
        short SizeOfFontStack;
        short SizeOfFocusScopeStack;
        short SizeOfGroupStack;
        short SizeOfItemFlagsStack;
        short SizeOfBeginPopupStack;
        short SizeOfDisabledStack;
    }

    struct ImGuiOldColumnData {
        float OffsetNorm; /// Column start offset, normalized 0.0 (far left) -> 1.0 (far right)
        float OffsetNormBeforeResize;
        ImGuiOldColumnFlags Flags; /// Not exposed
        ImRect ClipRect;
    }

    struct ImGuiDockRequest {
        ImGuiDockRequestType Type;
        ImGuiWindow* DockTargetWindow; /// Destination/Target Window to dock into (may be a loose window or a DockNode, might be NULL in which case DockTargetNode cannot be NULL)
        ImGuiDockNode* DockTargetNode; /// Destination/Target Node to dock into
        ImGuiWindow* DockPayload; /// Source/Payload window to dock (may be a loose window or a DockNode), [Optional]
        ImGuiDir DockSplitDir;
        float DockSplitRatio;
        bool DockSplitOuter;
        ImGuiWindow* UndockTargetWindow;
        ImGuiDockNode* UndockTargetNode;
    }

    /// sizeof() ~ 592 bytes + heap allocs described in TableBeginInitMemory()
    struct ImGuiTable {
        ImGuiID ID;
        ImGuiTableFlags Flags;
        void* RawData; /// Single allocation to hold Columns[], DisplayOrderToIndex[], and RowCellData[]
        ImGuiTableTempData* TempData; /// Transient data while table is active. Point within g.CurrentTableStack[]
        ImSpan!(ImGuiTableColumn) Columns; /// Point within RawData[]
        ImSpan!(ImGuiTableColumnIdx) DisplayOrderToIndex; /// Point within RawData[]. Store display order of columns (when not reordered, the values are 0...Count-1)
        ImSpan!(ImGuiTableCellData) RowCellData; /// Point within RawData[]. Store cells background requests for current row.
        ImBitArrayPtr EnabledMaskByDisplayOrder; /// Column DisplayOrder -> IsEnabled map
        ImBitArrayPtr EnabledMaskByIndex; /// Column Index -> IsEnabled map (== not hidden by user/api) in a format adequate for iterating column without touching cold data
        ImBitArrayPtr VisibleMaskByIndex; /// Column Index -> IsVisibleX|IsVisibleY map (== not hidden by user/api && not hidden by scrolling/cliprect)
        ImGuiTableFlags SettingsLoadedFlags; /// Which data were loaded from the .ini file (e.g. when order is not altered we won't save order)
        int SettingsOffset; /// Offset in g.SettingsTables
        int LastFrameActive;
        int ColumnsCount; /// Number of columns declared in BeginTable()
        int CurrentRow;
        int CurrentColumn;
        ImS16 InstanceCurrent; /// Count of BeginTable() calls with same ID in the same frame (generally 0). This is a little bit similar to BeginCount for a window, but multiple tables with the same ID are multiple tables, they are just synced.
        ImS16 InstanceInteracted; /// Mark which instance (generally 0) of the same ID is being interacted with
        float RowPosY1;
        float RowPosY2;
        float RowMinHeight; /// Height submitted to TableNextRow()
        float RowCellPaddingY; /// Top and bottom padding. Reloaded during row change.
        float RowTextBaseline;
        float RowIndentOffsetX;
        ImGuiTableRowFlags RowFlags; /// Current row flags, see ImGuiTableRowFlags_
        ImGuiTableRowFlags LastRowFlags;
        int RowBgColorCounter; /// Counter for alternating background colors (can be fast-forwarded by e.g clipper), not same as CurrentRow because header rows typically don't increase this.
        ImU32[2] RowBgColor; /// Background color override for current row.
        ImU32 BorderColorStrong;
        ImU32 BorderColorLight;
        float BorderX1;
        float BorderX2;
        float HostIndentX;
        float MinColumnWidth;
        float OuterPaddingX;
        float CellPaddingX; /// Padding from each borders. Locked in BeginTable()/Layout.
        float CellSpacingX1; /// Spacing between non-bordered cells. Locked in BeginTable()/Layout.
        float CellSpacingX2;
        float InnerWidth; /// User value passed to BeginTable(), see comments at the top of BeginTable() for details.
        float ColumnsGivenWidth; /// Sum of current column width
        float ColumnsAutoFitWidth; /// Sum of ideal column width in order nothing to be clipped, used for auto-fitting and content width submission in outer window
        float ColumnsStretchSumWeights; /// Sum of weight of all enabled stretching columns
        float ResizedColumnNextWidth;
        float ResizeLockMinContentsX2; /// Lock minimum contents width while resizing down in order to not create feedback loops. But we allow growing the table.
        float RefScale; /// Reference scale to be able to rescale columns on font/dpi changes.
        float AngledHeadersHeight; /// Set by TableAngledHeadersRow(), used in TableUpdateLayout()
        float AngledHeadersSlope; /// Set by TableAngledHeadersRow(), used in TableUpdateLayout()
        ImRect OuterRect; /// Note: for non-scrolling table, OuterRect.Max.y is often FLT_MAX until EndTable(), unless a height has been specified in BeginTable().
        ImRect InnerRect; /// InnerRect but without decoration. As with OuterRect, for non-scrolling tables, InnerRect.Max.y is "
        ImRect WorkRect;
        ImRect InnerClipRect;
        ImRect BgClipRect; /// We use this to cpu-clip cell background color fill, evolve during the frame as we cross frozen rows boundaries
        ImRect Bg0ClipRectForDrawCmd; /// Actual ImDrawCmd clip rect for BG0/1 channel. This tends to be == OuterWindow->ClipRect at BeginTable() because output in BG0/BG1 is cpu-clipped
        ImRect Bg2ClipRectForDrawCmd; /// Actual ImDrawCmd clip rect for BG2 channel. This tends to be a correct, tight-fit, because output to BG2 are done by widgets relying on regular ClipRect.
        ImRect HostClipRect; /// This is used to check if we can eventually merge our columns draw calls into the current draw call of the current window.
        ImRect HostBackupInnerClipRect; /// Backup of InnerWindow->ClipRect during PushTableBackground()/PopTableBackground()
        ImGuiWindow* OuterWindow; /// Parent window for the table
        ImGuiWindow* InnerWindow; /// Window holding the table data (== OuterWindow or a child window)
        ImGuiTextBuffer ColumnsNames; /// Contiguous buffer holding columns names
        ImDrawListSplitter* DrawSplitter; /// Shortcut to TempData->DrawSplitter while in table. Isolate draw commands per columns to avoid switching clip rect constantly
        ImGuiTableInstanceData InstanceDataFirst;
        ImVector!(ImGuiTableInstanceData) InstanceDataExtra; /// FIXME-OPT: Using a small-vector pattern would be good.
        ImGuiTableColumnSortSpecs SortSpecsSingle;
        ImVector!(ImGuiTableColumnSortSpecs) SortSpecsMulti; /// FIXME-OPT: Using a small-vector pattern would be good.
        ImGuiTableSortSpecs SortSpecs; /// Public facing sorts specs, this is what we return in TableGetSortSpecs()
        ImGuiTableColumnIdx SortSpecsCount;
        ImGuiTableColumnIdx ColumnsEnabledCount; /// Number of enabled columns (<= ColumnsCount)
        ImGuiTableColumnIdx ColumnsEnabledFixedCount; /// Number of enabled columns using fixed width (<= ColumnsCount)
        ImGuiTableColumnIdx DeclColumnsCount; /// Count calls to TableSetupColumn()
        ImGuiTableColumnIdx AngledHeadersCount; /// Count columns with angled headers
        ImGuiTableColumnIdx HoveredColumnBody; /// Index of column whose visible region is being hovered. Important: == ColumnsCount when hovering empty region after the right-most column!
        ImGuiTableColumnIdx HoveredColumnBorder; /// Index of column whose right-border is being hovered (for resizing).
        ImGuiTableColumnIdx HighlightColumnHeader; /// Index of column which should be highlighted.
        ImGuiTableColumnIdx AutoFitSingleColumn; /// Index of single column requesting auto-fit.
        ImGuiTableColumnIdx ResizedColumn; /// Index of column being resized. Reset when InstanceCurrent==0.
        ImGuiTableColumnIdx LastResizedColumn; /// Index of column being resized from previous frame.
        ImGuiTableColumnIdx HeldHeaderColumn; /// Index of column header being held.
        ImGuiTableColumnIdx ReorderColumn; /// Index of column being reordered. (not cleared)
        ImGuiTableColumnIdx ReorderColumnDir; /// -1 or +1
        ImGuiTableColumnIdx LeftMostEnabledColumn; /// Index of left-most non-hidden column.
        ImGuiTableColumnIdx RightMostEnabledColumn; /// Index of right-most non-hidden column.
        ImGuiTableColumnIdx LeftMostStretchedColumn; /// Index of left-most stretched column.
        ImGuiTableColumnIdx RightMostStretchedColumn; /// Index of right-most stretched column.
        ImGuiTableColumnIdx ContextPopupColumn; /// Column right-clicked on, of -1 if opening context menu from a neutral/empty spot
        ImGuiTableColumnIdx FreezeRowsRequest; /// Requested frozen rows count
        ImGuiTableColumnIdx FreezeRowsCount; /// Actual frozen row count (== FreezeRowsRequest, or == 0 when no scrolling offset)
        ImGuiTableColumnIdx FreezeColumnsRequest; /// Requested frozen columns count
        ImGuiTableColumnIdx FreezeColumnsCount; /// Actual frozen columns count (== FreezeColumnsRequest, or == 0 when no scrolling offset)
        ImGuiTableColumnIdx RowCellDataCurrent; /// Index of current RowCellData[] entry in current row
        ImGuiTableDrawChannelIdx DummyDrawChannel; /// Redirect non-visible columns here.
        ImGuiTableDrawChannelIdx Bg2DrawChannelCurrent; /// For Selectable() and other widgets drawing across columns after the freezing line. Index within DrawSplitter.Channels[]
        ImGuiTableDrawChannelIdx Bg2DrawChannelUnfrozen;
        ImS8 NavLayer; /// ImGuiNavLayer at the time of BeginTable().
        bool IsLayoutLocked; /// Set by TableUpdateLayout() which is called when beginning the first row.
        bool IsInsideRow; /// Set when inside TableBeginRow()/TableEndRow().
        bool IsInitializing;
        bool IsSortSpecsDirty;
        bool IsUsingHeaders; /// Set when the first row had the ImGuiTableRowFlags_Headers flag.
        bool IsContextPopupOpen; /// Set when default context menu is open (also see: ContextPopupColumn, InstanceInteracted).
        bool DisableDefaultContextMenu; /// Disable default context menu contents. You may submit your own using TableBeginContextMenuPopup()/EndPopup()
        bool IsSettingsRequestLoad;
        bool IsSettingsDirty; /// Set when table settings have changed and needs to be reported into ImGuiTableSetttings data.
        bool IsDefaultDisplayOrder; /// Set when display order is unchanged from default (DisplayOrder contains 0...Count-1)
        bool IsResetAllRequest;
        bool IsResetDisplayOrderRequest;
        bool IsUnfrozenRows; /// Set when we got past the frozen row.
        bool IsDefaultSizingPolicy; /// Set if user didn't explicitly set a sizing policy in BeginTable()
        bool IsActiveIdAliveBeforeTable;
        bool IsActiveIdInTable;
        bool HasScrollbarYCurr; /// Whether ANY instance of this table had a vertical scrollbar during the current frame.
        bool HasScrollbarYPrev; /// Whether ANY instance of this table had a vertical scrollbar during the previous.
        bool MemoryCompacted;
        bool HostSkipItems; /// Backup of InnerWindow->SkipItem at the end of BeginTable(), because we will overwrite InnerWindow->SkipItem on a per-column basis
    }

    /// Output of ImFontAtlas::GetCustomRect() when using custom rectangles.
    /// Those values may not be cached/stored as they are only valid for the current value of atlas->TexRef
    /// (this is in theory derived from ImTextureRect but we use separate structures for reasons)
    struct ImFontAtlasRect {
        ushort x; /// Position (in current texture)
        ushort y; /// Position (in current texture)
        ushort w; /// Size
        ushort h; /// Size
        ImVec2 uv0; /// UV coordinates (in current texture)
        ImVec2 uv1; /// UV coordinates (in current texture)
    }

    /// Transient per-window data, reset at the beginning of the frame. This used to be called ImGuiDrawContext, hence the DC variable name in ImGuiWindow.
    /// (That's theory, in practice the delimitation between ImGuiWindow and ImGuiWindowTempData is quite tenuous and could be reconsidered..)
    /// (This doesn't need a constructor because we zero-clear it as part of ImGuiWindow and all frame-temporary data are setup on Begin)
    struct ImGuiWindowTempData {
         
            /// Layout
        ImVec2 CursorPos; /// Current emitting position, in absolute coordinates.
        ImVec2 CursorPosPrevLine;
        ImVec2 CursorStartPos; /// Initial position after Begin(), generally ~ window position + WindowPadding.
        ImVec2 CursorMaxPos; /// Used to implicitly calculate ContentSize at the beginning of next frame, for scrolling range and auto-resize. Always growing during the frame.
        ImVec2 IdealMaxPos; /// Used to implicitly calculate ContentSizeIdeal at the beginning of next frame, for auto-resize only. Always growing during the frame.
        ImVec2 CurrLineSize;
        ImVec2 PrevLineSize;
        float CurrLineTextBaseOffset; /// Baseline offset (0.0f by default on a new line, generally == style.FramePadding.y when a framed item has been added).
        float PrevLineTextBaseOffset;
        bool IsSameLine;
        bool IsSetPos;
        ImVec1 Indent; /// Indentation / start position from left of window (increased by TreePush/TreePop, etc.)
        ImVec1 ColumnsOffset; /// Offset to the current column (if ColumnsCurrent > 0). FIXME: This and the above should be a stack to allow use cases like Tree->Column->Tree. Need revamp columns API.
        ImVec1 GroupOffset;
        ImVec2 CursorStartPosLossyness; /// Record the loss of precision of CursorStartPos due to really large scrolling amount. This is used by clipper to compensate and fix the most common use case of large scroll area.
             /// Keyboard/Gamepad navigation
        ImGuiNavLayer NavLayerCurrent; /// Current layer, 0..31 (we currently only use 0..1)
        short NavLayersActiveMask; /// Which layers have been written to (result from previous frame)
        short NavLayersActiveMaskNext; /// Which layers have been written to (accumulator for current frame)
        bool NavIsScrollPushableX; /// Set when current work location may be scrolled horizontally when moving left / right. This is generally always true UNLESS within a column.
        bool NavHideHighlightOneFrame;
        bool NavWindowHasScrollY; /// Set per window when scrolling can be used (== ScrollMax.y > 0.0f)
             /// Miscellaneous
        bool MenuBarAppending; /// FIXME: Remove this
        ImVec2 MenuBarOffset; /// MenuBarOffset.x is sort of equivalent of a per-layer CursorPos.x, saved/restored as we switch to the menu bar. The only situation when MenuBarOffset.y is > 0 if when (SafeAreaPadding.y > FramePadding.y), often used on TVs.
        ImGuiMenuColumns MenuColumns; /// Simplified columns storage for menu items measurement
        int TreeDepth; /// Current tree depth.
        ImU32 TreeHasStackDataDepthMask; /// Store whether given depth has ImGuiTreeNodeStackData data. Could be turned into a ImU64 if necessary.
        ImU32 TreeRecordsClippedNodesY2Mask; /// Store whether we should keep recording Y2. Cleared when passing clip max. Equivalent TreeHasStackDataDepthMask value should always be set.
        ImVector!(ImGuiWindow*) ChildWindows;
        ImGuiStorage* StateStorage; /// Current persistent per-window storage (store e.g. tree node open/close state)
        ImGuiOldColumns* CurrentColumns; /// Current columns set
        int CurrentTableIdx; /// Current table index (into g.Tables)
        ImGuiLayoutType LayoutType;
        ImGuiLayoutType ParentLayoutType; /// Layout type of parent window at the time of Begin()
        ImU32 ModalDimBgColor;
             /// Status flags
        ImGuiItemStatusFlags WindowItemStatusFlags;
        ImGuiItemStatusFlags ChildItemStatusFlags;
        ImGuiItemStatusFlags DockTabItemStatusFlags;
        ImRect DockTabItemRect;
             /// Local parameters stacks
            /// We store the current settings outside of the vectors to increase memory locality (reduce cache misses). The vectors are rarely modified. Also it allows us to not heap allocate for short-lived windows which are not using those settings.
        float ItemWidth; /// Current item width (>0.0: width in pixels, <0.0: align xx pixels to the right of window).
        float TextWrapPos; /// Current text wrap pos.
        ImVector!(float) ItemWidthStack; /// Store item widths to restore (attention: .back() is not == ItemWidth)
        ImVector!(float) TextWrapPosStack; /// Store text wrap pos to restore (attention: .back() is not == TextWrapPos)
    }

    /// Optional helper to apply multi-selection requests to existing randomly accessible storage.
    /// Convenient if you want to quickly wire multi-select API on e.g. an array of bool or items storing their own selection state.
    struct ImGuiSelectionExternalStorage {
         
            /// Members
        void* UserData; /// User data for use by adapter function                                /// e.g. selection.UserData = (void*)my_items;
        void function(ImGuiSelectionExternalStorage* self,int idx,bool selected) AdapterSetItemSelected; /// e.g. AdapterSetItemSelected = [](ImGuiSelectionExternalStorage* self, int idx, bool selected)  ((MyItems**)self->UserData)[idx]->Selected = selected; 
    }

    /// Hold rendering data for one glyph.
    /// (Note: some language parsers may fail to convert the bitfield members, in this case maybe drop store a single u32 or we can rework this)
    struct ImFontGlyph {
        uint Colored; /// Flag to indicate glyph is colored and should generally ignore tinting (make it usable with no shift on little-endian as this is used in loops)
        uint Visible; /// Flag to indicate glyph has no visible pixels (e.g. space). Allow early out when rendering.
        uint SourceIdx; /// Index of source in parent font
        uint Codepoint; /// 0x0000..0x10FFFF
        float AdvanceX; /// Horizontal distance to advance cursor/layout position.
        float X0; /// Glyph corners. Offsets from current cursor/layout position.
        float Y0; /// Glyph corners. Offsets from current cursor/layout position.
        float X1; /// Glyph corners. Offsets from current cursor/layout position.
        float Y1; /// Glyph corners. Offsets from current cursor/layout position.
        float U0; /// Texture coordinates for the current value of ImFontAtlas->TexRef. Cached equivalent of calling GetCustomRect() with PackId.
        float V0; /// Texture coordinates for the current value of ImFontAtlas->TexRef. Cached equivalent of calling GetCustomRect() with PackId.
        float U1; /// Texture coordinates for the current value of ImFontAtlas->TexRef. Cached equivalent of calling GetCustomRect() with PackId.
        float V1; /// Texture coordinates for the current value of ImFontAtlas->TexRef. Cached equivalent of calling GetCustomRect() with PackId.
        int PackId; /// [Internal] ImFontAtlasRectId value (FIXME: Cold data, could be moved elsewhere?)
    }

    struct ImGuiNextItemData {
        ImGuiNextItemDataFlags HasFlags; /// Called HasFlags instead of Flags to avoid mistaking this
        ImGuiItemFlags ItemFlags; /// Currently only tested/used for ImGuiItemFlags_AllowOverlap and ImGuiItemFlags_HasSelectionUserData.
             /// Members below are NOT cleared by ItemAdd() meaning they are still valid during e.g. NavProcessItem(). Always rely on HasFlags.
        ImGuiID FocusScopeId; /// Set by SetNextItemSelectionUserData()
        ImGuiSelectionUserData SelectionUserData; /// Set by SetNextItemSelectionUserData() (note that NULL/0 is a valid value, we use -1 == ImGuiSelectionUserData_Invalid to mark invalid values)
        float Width; /// Set by SetNextItemWidth()
        ImGuiKeyChord Shortcut; /// Set by SetNextItemShortcut()
        ImGuiInputFlags ShortcutFlags; /// Set by SetNextItemShortcut()
        bool OpenVal; /// Set by SetNextItemOpen()
        ImU8 OpenCond; /// Set by SetNextItemOpen()
        ImGuiDataTypeStorage RefVal; /// Not exposed yet, for ImGuiInputTextFlags_ParseEmptyAsRefVal
        ImGuiID StorageId; /// Set by SetNextItemStorageID()
    }

    struct ImGuiStyleVarInfo {
        ImU32 Count; /// 1+
        ImGuiDataType DataType;
        ImU32 Offset; /// Offset in parent structure
    }

        /// [Internal]
    struct ImGuiTextRange {
        const(char)* b;
        const(char)* e;
    }

    /// Returned by GetTypingSelectRequest(), designed to eventually be public.
    struct ImGuiTypingSelectRequest {
        ImGuiTypingSelectFlags Flags; /// Flags passed to GetTypingSelectRequest()
        int SearchBufferLen;
        const(char)* SearchBuffer; /// Search buffer contents (use full string. unless SingleCharMode is set, in which case use SingleCharSize).
        bool SelectRequest; /// Set when buffer was modified this frame, requesting a selection.
        bool SingleCharMode; /// Notify when buffer contains same character repeated, to implement special mode. In this situation it preferred to not display any on-screen search indication.
        ImS8 SingleCharSize; /// Length in bytes of first letter codepoint (1 for ascii, 2-4 for UTF-8). If (SearchBufferLen==RepeatCharSize) only 1 letter has been input.
    }

    struct ImDrawDataBuilder {
        ImVector!(ImDrawList*)*[2] Layers; /// Pointers to global layers for: regular, tooltip. LayersP[0] is owned by DrawData.
        ImVector!(ImDrawList*) LayerData1;
    }

    struct ImGuiInputEventMouseWheel {
        float WheelX;
        float WheelY;
        ImGuiMouseSource MouseSource;
    }

    /// [Internal] Storage used by IsKeyDown(), IsKeyPressed() etc functions.
    /// If prior to 1.87 you used io.KeysDownDuration[] (which was marked as internal), you should use GetKeyData(key)->DownDuration and *NOT* io.KeysData[key]->DownDuration.
    struct ImGuiKeyData {
        bool Down; /// True for if key is down
        float DownDuration; /// Duration the key has been down (<0.0f: not pressed, 0.0f: just pressed, >0.0f: time held)
        float DownDurationPrev; /// Last frame duration the key has been down
        float AnalogValue; /// 0.0f..1.0f for gamepad values
    }

    /// Persistent storage for multi-select (as long as selection is alive)
    struct ImGuiMultiSelectState {
        ImGuiWindow* Window;
        ImGuiID ID;
        int LastFrameActive; /// Last used frame-count, for GC.
        int LastSelectionSize; /// Set by BeginMultiSelect() based on optional info provided by user. May be -1 if unknown.
        ImS8 RangeSelected; /// -1 (don't have) or true/false
        ImS8 NavIdSelected; /// -1 (don't have) or true/false
        ImGuiSelectionUserData RangeSrcItem; //
        ImGuiSelectionUserData NavIdItem; /// SetNextItemSelectionUserData() value for NavId (if part of submitted items)
    }

    /// Note that Max is exclusive, so perhaps should be using a Begin/End convention.
    struct ImGuiListClipperRange {
        int Min;
        int Max;
        bool PosToIndexConvert; /// Begin/End are absolute position (will be converted to indices later)
        ImS8 PosToIndexOffsetMin; /// Add to Min after converting to indices
        ImS8 PosToIndexOffsetMax; /// Add to Min after converting to indices
    }

    /// Font runtime data and rendering
    /// - ImFontAtlas automatically loads a default embedded font for you if you didn't load one manually.
    /// - Since 1.92.X a font may be rendered as any size! Therefore a font doesn't have one specific size.
    /// - Use 'font->GetFontBaked(size)' to retrieve the ImFontBaked* corresponding to a given size.
    /// - If you used g.Font + g.FontSize (which is frequent from the ImGui layer), you can use g.FontBaked as a shortcut, as g.FontBaked == g.Font->GetFontBaked(g.FontSize).
    struct ImFont {
         
            /// [Internal] Members: Hot ~12-20 bytes
        ImFontBaked* LastBaked; /// 4-8   /// Cache last bound baked. NEVER USE DIRECTLY. Use GetFontBaked().
        ImFontAtlas* ContainerAtlas; /// 4-8   /// What we have been loaded into.
        ImFontFlags Flags; /// 4     /// Font flags.
        float CurrentRasterizerDensity; /// Current rasterizer density. This is a varying state of the font.
             /// [Internal] Members: Cold ~24-52 bytes
            /// Conceptually Sources[] is the list of font sources merged to create this font.
        ImGuiID FontId; /// Unique identifier for the font
        float LegacySize; /// 4     /// in  /// Font size passed to AddFont(). Use for old code calling PushFont() expecting to use that size. (use ImGui::GetFontBaked() to get font baked at current bound size).
        ImVector!(ImFontConfig*) Sources; /// 16    /// in  /// List of sources. Pointers within ContainerAtlas->Sources[]
        ImWchar EllipsisChar; /// 2-4   /// out /// Character used for ellipsis rendering ('...').
        ImWchar FallbackChar; /// 2-4   /// out /// Character used if a glyph isn't found (U+FFFD, '?')
        ImU8[(0x10FFFF+1)/8192/8] Used8kPagesMap; /// 1 bytes if ImWchar=ImWchar16, 16 bytes if ImWchar==ImWchar32. Store 1-bit for each block of 4K codepoints that has one active glyph. This is mainly used to facilitate iterations across all used codepoints.
        bool EllipsisAutoBake; /// 1     ///     /// Mark when the "..." glyph needs to be generated.
        ImGuiStorage RemapPairs; /// 16    ///     /// Remapping pairs when using AddRemapChar(), otherwise empty.
    }

    /// ImVec4: 4D vector used to store clipping rectangles, colors etc. [Compile-time configurable type]
    struct ImVec4 {
        float x;
        float y;
        float z;
        float w;
    }

    struct stbrp_context_opaque {
        char[80] data;
    }

    struct ImGuiDockContext {
        ImGuiStorage Nodes; /// Map ID -> ImGuiDockNode*: Active nodes
        ImVector!(ImGuiDockRequest) Requests;
        ImVector!(ImGuiDockNodeSettings) NodesSettings;
        bool WantFullRebuild;
    }

    struct ImGuiSettingsHandler {
        const(char)* TypeName; /// Short description stored in .ini file. Disallowed characters: '[' ']'
        ImGuiID TypeHash; /// == ImHashStr(TypeName)
        void function(ImGuiContext* ctx,ImGuiSettingsHandler* handler) ClearAllFn; /// Clear all settings data
        void function(ImGuiContext* ctx,ImGuiSettingsHandler* handler) ReadInitFn; /// Read: Called before reading (in registration order)
        void* function(ImGuiContext* ctx,ImGuiSettingsHandler* handler,const(char)* name) ReadOpenFn; /// Read: Called when entering into a new ini entry e.g. "[Window][Name]"
        void function(ImGuiContext* ctx,ImGuiSettingsHandler* handler,void* entry,const(char)* line) ReadLineFn; /// Read: Called for every line of text within an ini entry
        void function(ImGuiContext* ctx,ImGuiSettingsHandler* handler) ApplyAllFn; /// Read: Called after reading (in registration order)
        void function(ImGuiContext* ctx,ImGuiSettingsHandler* handler,ImGuiTextBuffer* out_buf) WriteAllFn; /// Write: Output every entries into 'out_buf'
        void* UserData;
    }

    /// Split/Merge functions are used to split the draw list into different layers which can be drawn into out of order.
    /// This is used by the Columns/Tables API, so items of each column can be batched together in a same draw call.
    struct ImDrawListSplitter {
        int _Current; /// Current channel number (0)
        int _Count; /// Number of active channels (1+)
        ImVector!(ImDrawChannel) _Channels; /// Draw channels (not resized down so _Count might be < Channels.Size)
    }

    /// [Internal] Key+Value for ImGuiStorage
    struct ImGuiStoragePair {
        ImGuiID key;
        union { int val_i; float val_f; void* val_p;} ;
    }

    /// [Internal] For use by ImDrawListSplitter
    struct ImDrawChannel {
        ImVector!(ImDrawCmd) _CmdBuffer;
        ImVector!(ImDrawIdx) _IdxBuffer;
    }

    /// sizeof() ~ 16
    struct ImGuiTableColumnSettings {
        float WidthOrWeight;
        ImGuiID UserID;
        ImGuiTableColumnIdx Index;
        ImGuiTableColumnIdx DisplayOrder;
        ImGuiTableColumnIdx SortOrder;
        ImU8 SortDirection;
        ImS8 IsEnabled; /// "Visible" in ini file
        ImU8 IsStretch;
    }

    /// Helper: Growable text buffer for logging/accumulating text
    /// (this could be called 'ImGuiTextBuilder' / 'ImGuiStringBuilder')
    struct ImGuiTextBuffer {
        ImVector!(char) Buf;
    }

    /// Helper: Manually clip large list of items.
    /// If you have lots evenly spaced items and you have random access to the list, you can perform coarse
    /// clipping based on visibility to only submit items that are in view.
    /// The clipper calculates the range of visible items and advance the cursor to compensate for the non-visible items we have skipped.
    /// (Dear ImGui already clip items based on their bounds but: it needs to first layout the item to do so, and generally
    ///  fetching/submitting your own data incurs additional cost. Coarse clipping using ImGuiListClipper allows you to easily
    ///  scale using lists with tens of thousands of items without a problem)
    /// Usage:
    ///   ImGuiListClipper clipper;
    ///   clipper.Begin(1000);         /// We have 1000 elements, evenly spaced.
    ///   while (clipper.Step())
    ///       for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
    ///           ImGui::Text("line number %d", i);
    /// Generally what happens is:
    /// - Clipper lets you process the first element (DisplayStart = 0, DisplayEnd = 1) regardless of it being visible or not.
    /// - User code submit that one element.
    /// - Clipper can measure the height of the first element
    /// - Clipper calculate the actual range of elements to display based on the current clipping rectangle, position the cursor before the first visible element.
    /// - User code submit visible elements.
    /// - The clipper also handles various subtleties related to keyboard/gamepad navigation, wrapping etc.
    struct ImGuiListClipper {
        ImGuiContext* Ctx; /// Parent UI context
        int DisplayStart; /// First item to display, updated by each call to Step()
        int DisplayEnd; /// End of items to display (exclusive)
        int ItemsCount; /// [Internal] Number of items
        float ItemsHeight; /// [Internal] Height of item after a first step and item submission can calculate it
        double StartPosY; /// [Internal] Cursor position at the time of Begin() or after table frozen rows are all processed
        double StartSeekOffsetY; /// [Internal] Account for frozen rows in a table and initial loss of precision in very large windows.
        void* TempData; /// [Internal] Internal data
    }

    struct ImGuiInputEventMouseButton {
        int Button;
        bool Down;
        ImGuiMouseSource MouseSource;
    }

    /// Storage for SetNexWindow** functions
    struct ImGuiNextWindowData {
        ImGuiNextWindowDataFlags HasFlags;
             /// Members below are NOT cleared. Always rely on HasFlags.
        ImGuiCond PosCond;
        ImGuiCond SizeCond;
        ImGuiCond CollapsedCond;
        ImGuiCond DockCond;
        ImVec2 PosVal;
        ImVec2 PosPivotVal;
        ImVec2 SizeVal;
        ImVec2 ContentSizeVal;
        ImVec2 ScrollVal;
        ImGuiWindowFlags WindowFlags; /// Only honored by BeginTable()
        ImGuiChildFlags ChildFlags;
        bool PosUndock;
        bool CollapsedVal;
        ImRect SizeConstraintRect;
        ImGuiSizeCallback SizeCallback;
        void* SizeCallbackUserData;
        float BgAlphaVal; /// Override background alpha
        ImGuiID ViewportId;
        ImGuiID DockId;
        ImGuiWindowClass WindowClass;
        ImVec2 MenuBarOffsetMinVal; /// (Always on) This is not exposed publicly, so we don't clear it and it doesn't have a corresponding flag (could we? for consistency?)
        ImGuiWindowRefreshFlags RefreshFlagsVal;
    }

    /// (Optional) This is required when enabling multi-viewport. Represent the bounds of each connected monitor/display and their DPI.
    /// We use this information for multiple DPI support + clamping the position of popups and tooltips so they don't straddle multiple monitors.
    struct ImGuiPlatformMonitor {
        ImVec2 MainPos; /// Coordinates of the area displayed on this monitor (Min = upper left, Max = bottom right)
        ImVec2 MainSize; /// Coordinates of the area displayed on this monitor (Min = upper left, Max = bottom right)
        ImVec2 WorkPos; /// Coordinates without task bars / side bars / menu bars. Used to avoid positioning popups/tooltips inside this region. If you don't have this info, please copy the value for MainPos/MainSize.
        ImVec2 WorkSize; /// Coordinates without task bars / side bars / menu bars. Used to avoid positioning popups/tooltips inside this region. If you don't have this info, please copy the value for MainPos/MainSize.
        float DpiScale; /// 1.0f = 96 DPI
        void* PlatformHandle; /// Backend dependant data (e.g. HMONITOR, GLFWmonitor*, SDL Display Index, NSScreen*)
    }

    struct ImGuiMetricsConfig {
        bool ShowDebugLog;
        bool ShowIDStackTool;
        bool ShowWindowsRects;
        bool ShowWindowsBeginOrder;
        bool ShowTablesRects;
        bool ShowDrawCmdMesh;
        bool ShowDrawCmdBoundingBoxes;
        bool ShowTextEncodingViewer;
        bool ShowTextureUsedRect;
        bool ShowDockingNodes;
        int ShowWindowsRectsType;
        int ShowTablesRectsType;
        int HighlightMonitorIdx;
        ImGuiID HighlightViewportID;
        bool ShowFontPreview;
    }

    /// This extends ImGuiKeyData but only for named keys (legacy keys don't support the new features)
    /// Stored in main context (1 per named key). In the future it might be merged into ImGuiKeyData.
    struct ImGuiKeyOwnerData {
        ImGuiID OwnerCurr;
        ImGuiID OwnerNext;
        bool LockThisFrame; /// Reading this key requires explicit owner id (until end of frame). Set by ImGuiInputFlags_LockThisFrame.
        bool LockUntilRelease; /// Reading this key requires explicit owner id (until key is released). Set by ImGuiInputFlags_LockUntilRelease. When this is true LockThisFrame is always true as well.
    }

    /// Stacked style modifier, backup of modified data so we can restore it. Data type inferred from the variable.
    struct ImGuiStyleMod {
        ImGuiStyleVar VarIdx;
        union { int[2] BackupInt; float[2] BackupFloat;} ;
    }

    /// - Currently represents the Platform Window created by the application which is hosting our Dear ImGui windows.
    /// - With multi-viewport enabled, we extend this concept to have multiple active viewports.
    /// - In the future we will extend this concept further to also represent Platform Monitor and support a "no main platform window" operation mode.
    /// - About Main Area vs Work Area:
    ///   - Main Area = entire viewport.
    ///   - Work Area = entire viewport minus sections used by main menu bars (for platform windows), or by task bar (for platform monitor).
    ///   - Windows are generally trying to stay within the Work Area of their host viewport.
    struct ImGuiViewport {
        ImGuiID ID; /// Unique identifier for the viewport
        ImGuiViewportFlags Flags; /// See ImGuiViewportFlags_
        ImVec2 Pos; /// Main Area: Position of the viewport (Dear ImGui coordinates are the same as OS desktop/native coordinates)
        ImVec2 Size; /// Main Area: Size of the viewport.
        ImVec2 FramebufferScale; /// Density of the viewport for Retina display (always 1,1 on Windows, may be 2,2 etc on macOS/iOS). This will affect font rasterizer density.
        ImVec2 WorkPos; /// Work Area: Position of the viewport minus task bars, menus bars, status bars (>= Pos)
        ImVec2 WorkSize; /// Work Area: Size of the viewport minus task bars, menu bars, status bars (<= Size)
        float DpiScale; /// 1.0f = 96 DPI = No extra scale.
        ImGuiID ParentViewportId; /// (Advanced) 0: no parent. Instruct the platform backend to setup a parent/child relationship between platform windows.
        ImDrawData* DrawData; /// The ImDrawData corresponding to this viewport. Valid after Render() and until the next call to NewFrame().
             /// Platform/Backend Dependent Data
            /// Our design separate the Renderer and Platform backends to facilitate combining default backends with each others.
            /// When our create your own backend for a custom engine, it is possible that both Renderer and Platform will be handled
            /// by the same system and you may not need to use all the UserData/Handle fields.
            /// The library never uses those fields, they are merely storage to facilitate backend implementation.
        void* RendererUserData; /// void* to hold custom data structure for the renderer (e.g. swap chain, framebuffers etc.). generally set by your Renderer_CreateWindow function.
        void* PlatformUserData; /// void* to hold custom data structure for the OS / platform (e.g. windowing info, render context). generally set by your Platform_CreateWindow function.
        void* PlatformHandle; /// void* to hold higher-level, platform window handle (e.g. HWND for Win32 backend, Uint32 WindowID for SDL, GLFWWindow* for GLFW), for FindViewportByPlatformHandle().
        void* PlatformHandleRaw; /// void* to hold lower-level, platform-native window handle (always HWND on Win32 platform, unused for other platforms).
        bool PlatformWindowCreated; /// Platform window has been created (Platform_CreateWindow() has been called). This is false during the first frame where a viewport is being created.
        bool PlatformRequestMove; /// Platform window requested move (e.g. window was moved by the OS / host window manager, authoritative position will be OS window position)
        bool PlatformRequestResize; /// Platform window requested resize (e.g. window was resized by the OS / host window manager, authoritative size will be OS window size)
        bool PlatformRequestClose; /// Platform window requested closure (e.g. window was moved by the OS / host window manager, e.g. pressing ALT-F4)
    }

    /// Optional helper to store multi-selection state + apply multi-selection requests.
    /// - Used by our demos and provided as a convenience to easily implement basic multi-selection.
    /// - Iterate selection with 'void* it = NULL; ImGuiID id; while (selection.GetNextSelectedItem(&it, &id))  ... '
    ///   Or you can check 'if (Contains(id))  ... ' for each possible object if their number is not too high to iterate.
    /// - USING THIS IS NOT MANDATORY. This is only a helper and not a required API.
    /// To store a multi-selection, in your application you could:
    /// - Use this helper as a convenience. We use our simple key->value ImGuiStorage as a std::set<ImGuiID> replacement.
    /// - Use your own external storage: e.g. std::set<MyObjectId>, std::vector<MyObjectId>, interval trees, intrusively stored selection etc.
    /// In ImGuiSelectionBasicStorage we:
    /// - always use indices in the multi-selection API (passed to SetNextItemSelectionUserData(), retrieved in ImGuiMultiSelectIO)
    /// - use the AdapterIndexToStorageId() indirection layer to abstract how persistent selection data is derived from an index.
    /// - use decently optimized logic to allow queries and insertion of very large selection sets.
    /// - do not preserve selection order.
    /// Many combinations are possible depending on how you prefer to store your items and how you prefer to store your selection.
    /// Large applications are likely to eventually want to get rid of this indirection layer and do their own thing.
    /// See https://github.com/ocornut/imgui/wiki/Multi-Select for details and pseudo-code using this helper.
    struct ImGuiSelectionBasicStorage {
         
            /// Members
        int Size; ///          /// Number of selected items, maintained by this helper.
        bool PreserveOrder; /// = false  /// GetNextSelectedItem() will return ordered selection (currently implemented by two additional sorts of selection. Could be improved)
        void* UserData; /// = NULL   /// User data for use by adapter function        /// e.g. selection.UserData = (void*)my_items;
        ImGuiID function(ImGuiSelectionBasicStorage* self,int idx) AdapterIndexToStorageId; /// e.g. selection.AdapterIndexToStorageId = [](ImGuiSelectionBasicStorage* self, int idx)  return ((MyItems**)self->UserData)[idx]->ID; ;
        int _SelectionOrder; /// [Internal] Increasing counter to store selection order
        ImGuiStorage _Storage; /// [Internal] Selection set. Think of this as similar to e.g. std::set<ImGuiID>. Prefer not accessing directly: iterate with GetNextSelectedItem().
    }

    struct ImGuiDockPreviewData {
        ImGuiDockNode FutureNode;
        bool IsDropAllowed;
        bool IsCenterAvailable;
        bool IsSidesAvailable; /// Hold your breath, grammar freaks..
        bool IsSplitDirExplicit; /// Set when hovered the drop rect (vs. implicit SplitDir==None when hovered the window)
        ImGuiDockNode* SplitNode;
        ImGuiDir SplitDir;
        float SplitRatio;
        ImRect[4+1] DropRectsDraw; /// May be slightly different from hit-testing drop rects used in DockNodeCalcDropRects()
    }

    /// [ALPHA] Rarely used / very advanced uses only. Use with SetNextWindowClass() and DockSpace() functions.
    /// Important: the content of this class is still highly WIP and likely to change and be refactored
    /// before we stabilize Docking features. Please be mindful if using this.
    /// Provide hints:
    /// - To the platform backend via altered viewport flags (enable/disable OS decoration, OS task bar icons, etc.)
    /// - To the platform backend for OS level parent/child relationships of viewport.
    /// - To the docking system for various options and filtering.
    struct ImGuiWindowClass {
        ImGuiID ClassId; /// User data. 0 = Default class (unclassed). Windows of different classes cannot be docked with each others.
        ImGuiID ParentViewportId; /// Hint for the platform backend. -1: use default. 0: request platform backend to not parent the platform. != 0: request platform backend to create a parent<>child relationship between the platform windows. Not conforming backends are free to e.g. parent every viewport to the main viewport or not.
        ImGuiID FocusRouteParentWindowId; /// ID of parent window for shortcut focus route evaluation, e.g. Shortcut() call from Parent Window will succeed when this window is focused.
        ImGuiViewportFlags ViewportFlagsOverrideSet; /// Viewport flags to set when a window of this class owns a viewport. This allows you to enforce OS decoration or task bar icon, override the defaults on a per-window basis.
        ImGuiViewportFlags ViewportFlagsOverrideClear; /// Viewport flags to clear when a window of this class owns a viewport. This allows you to enforce OS decoration or task bar icon, override the defaults on a per-window basis.
        ImGuiTabItemFlags TabItemFlagsOverrideSet; /// [EXPERIMENTAL] TabItem flags to set when a window of this class gets submitted into a dock node tab bar. May use with ImGuiTabItemFlags_Leading or ImGuiTabItemFlags_Trailing.
        ImGuiDockNodeFlags DockNodeFlagsOverrideSet; /// [EXPERIMENTAL] Dock node flags to set when a window of this class is hosted by a dock node (it doesn't have to be selected!)
        bool DockingAlwaysTabBar; /// Set to true to enforce single floating windows of this class always having their own docking node (equivalent of setting the global io.ConfigDockingAlwaysTabBar)
        bool DockingAllowUnclassed; /// Set to true to allow windows of this class to be docked/merged with an unclassed window. /// FIXME-DOCK: Move to DockNodeFlags override?
    }

    /// This is designed to be stored in a single ImChunkStream (1 header followed by N ImGuiTableColumnSettings, etc.)
    struct ImGuiTableSettings {
        ImGuiID ID; /// Set to 0 to invalidate/delete the setting
        ImGuiTableFlags SaveFlags; /// Indicate data we want to save using the Resizable/Reorderable/Sortable/Hideable flags (could be using its own flags..)
        float RefScale; /// Reference scale to be able to rescale columns on font/dpi changes.
        ImGuiTableColumnIdx ColumnsCount;
        ImGuiTableColumnIdx ColumnsCountMax; /// Maximum number of columns this settings instance can store, we can recycle a settings instance with lower number of columns but not higher
        bool WantApply; /// Set when loaded from .ini data (to enable merging/loading .ini data into an already running context)
    }

    /// Helper: ImVec2i (2D vector, integer)
    struct ImVec2i {
        int x;
        int y;
    }

    /// Load and rasterize multiple TTF/OTF fonts into a same texture. The font atlas will build a single texture holding:
    ///  - One or more fonts.
    ///  - Custom graphics data needed to render the shapes needed by Dear ImGui.
    ///  - Mouse cursor shapes for software cursor rendering (unless setting 'Flags |= ImFontAtlasFlags_NoMouseCursors' in the font atlas).
    ///  - If you don't call any AddFont*** functions, the default font embedded in the code will be loaded for you.
    /// It is the rendering backend responsibility to upload texture into your graphics API:
    ///  - ImGui_ImplXXXX_RenderDrawData() functions generally iterate platform_io->Textures[] to create/update/destroy each ImTextureData instance.
    ///  - Backend then set ImTextureData's TexID and BackendUserData.
    ///  - Texture id are passed back to you during rendering to identify the texture. Read FAQ entry about ImTextureID/ImTextureRef for more details.
    /// Legacy path:
    ///  - Call Build() + GetTexDataAsAlpha8() or GetTexDataAsRGBA32() to build and retrieve pixels data.
    ///  - Call SetTexID(my_tex_id); and pass the pointer/identifier to your texture in a format natural to your graphics API.
    /// Common pitfalls:
    /// - If you pass a 'glyph_ranges' array to AddFont*** functions, you need to make sure that your array persist up until the
    ///   atlas is build (when calling GetTexData*** or Build()). We only copy the pointer, not the data.
    /// - Important: By default, AddFontFromMemoryTTF() takes ownership of the data. Even though we are not writing to it, we will free the pointer on destruction.
    ///   You can set font_cfg->FontDataOwnedByAtlas=false to keep ownership of your data and it won't be freed,
    /// - Even though many functions are suffixed with "TTF", OTF data is supported just as well.
    /// - This is an old API and it is currently awkward for those and various other reasons! We will address them in the future!
    struct ImFontAtlas {
             /// Input
        ImFontAtlasFlags Flags; /// Build flags (see ImFontAtlasFlags_)
        ImTextureFormat TexDesiredFormat; /// Desired texture format (default to ImTextureFormat_RGBA32 but may be changed to ImTextureFormat_Alpha8).
        int TexGlyphPadding; /// FIXME: Should be called "TexPackPadding". Padding between glyphs within texture in pixels. Defaults to 1. If your rendering method doesn't rely on bilinear filtering you may set this to 0 (will also need to set AntiAliasedLinesUseTex = false).
        int TexMinWidth; /// Minimum desired texture width. Must be a power of two. Default to 512.
        int TexMinHeight; /// Minimum desired texture height. Must be a power of two. Default to 128.
        int TexMaxWidth; /// Maximum desired texture width. Must be a power of two. Default to 8192.
        int TexMaxHeight; /// Maximum desired texture height. Must be a power of two. Default to 8192.
        void* UserData; /// Store your own atlas related user-data (if e.g. you have multiple font atlas).
        ImTextureRef TexRef; /// Latest texture identifier == TexData->GetTexRef().
        ImTextureData* TexData; /// Latest texture.
             /// [Internal]
        ImVector!(ImTextureData*) TexList; /// Texture list (most often TexList.Size == 1). TexData is always == TexList.back(). DO NOT USE DIRECTLY, USE GetDrawData().Textures[]/GetPlatformIO().Textures[] instead!
        bool Locked; /// Marked as locked during ImGui::NewFrame()..EndFrame() scope if TexUpdates are not supported. Any attempt to modify the atlas will assert.
        bool RendererHasTextures; /// Copy of (BackendFlags & ImGuiBackendFlags_RendererHasTextures) from supporting context.
        bool TexIsBuilt; /// Set when texture was built matching current font input. Mostly useful for legacy IsBuilt() call.
        bool TexPixelsUseColors; /// Tell whether our texture data is known to use colors (rather than just alpha channel), in order to help backend select a format or conversion process.
        ImVec2 TexUvScale; /// = (1.0f/TexData->TexWidth, 1.0f/TexData->TexHeight). May change as new texture gets created.
        ImVec2 TexUvWhitePixel; /// Texture coordinates to a white pixel. May change as new texture gets created.
        ImVector!(ImFont*) Fonts; /// Hold all the fonts returned by AddFont*. Fonts[0] is the default font upon calling ImGui::NewFrame(), use ImGui::PushFont()/PopFont() to change the current font.
        ImVector!(ImFontConfig) Sources; /// Source/configuration data
        ImVec4[(32)+1] TexUvLines; /// UVs for baked anti-aliased lines
        int TexNextUniqueID; /// Next value to be stored in TexData->UniqueID
        int FontNextUniqueID; /// Next value to be stored in ImFont->FontID
        ImVector!(ImDrawListSharedData*) DrawListSharedDatas; /// List of users for this atlas. Typically one per Dear ImGui context.
        ImFontAtlasBuilder* Builder; /// Opaque interface to our data that doesn't need to be public and may be discarded when rebuilding.
        const(ImFontLoader)* FontLoader; /// Font loader opaque interface (default to stb_truetype, can be changed to use FreeType by defining IMGUI_ENABLE_FREETYPE). Don't set directly!
        const(char)* FontLoaderName; /// Font loader name (for display e.g. in About box) == FontLoader->Name
        void* FontLoaderData; /// Font backend opaque storage
        uint FontLoaderFlags; /// Shared flags (for all fonts) for font loader. THIS IS BUILD IMPLEMENTATION DEPENDENT (e.g. Per-font override is also available in ImFontConfig).
        int RefCount; /// Number of contexts using this atlas
        ImGuiContext* OwnerContext; /// Context which own the atlas will be in charge of updating and destroying it.
    }

    /// Store data emitted by TreeNode() for usage by TreePop()
    /// - To implement ImGuiTreeNodeFlags_NavLeftJumpsToParent: store the minimum amount of data
    ///   which we can't infer in TreePop(), to perform the equivalent of NavApplyItemToResult().
    ///   Only stored when the node is a potential candidate for landing on a Left arrow jump.
    struct ImGuiTreeNodeStackData {
        ImGuiID ID;
        ImGuiTreeNodeFlags TreeFlags;
        ImGuiItemFlags ItemFlags; /// Used for nav landing
        ImRect NavRect; /// Used for nav landing
        float DrawLinesX1;
        float DrawLinesToNodesY2;
        ImGuiTableColumnIdx DrawLinesTableColumn;
    }

    /// Parameters for TableAngledHeadersRowEx()
    /// This may end up being refactored for more general purpose.
    /// sizeof() ~ 12 bytes
    struct ImGuiTableHeaderData {
        ImGuiTableColumnIdx Index; /// Column index
        ImU32 TextColor;
        ImU32 BgColor0;
        ImU32 BgColor1;
    }

    /// Storage for PushFocusScope(), g.FocusScopeStack[], g.NavFocusRoute[]
    struct ImGuiFocusScopeData {
        ImGuiID ID;
        ImGuiID WindowID;
    }

    /// Temporary clipper data, buffers shared/reused between instances
    struct ImGuiListClipperData {
        ImGuiListClipper* ListClipper;
        float LossynessOffset;
        int StepNo;
        int ItemsFrozen;
        ImVector!(ImGuiListClipperRange) Ranges;
    }

    /// ImGuiViewport Private/Internals fields (cardinal sin: we are using inheritance!)
    /// Every instance of ImGuiViewport is in fact a ImGuiViewportP.
    struct ImGuiViewportP {
        ImGuiViewport _ImGuiViewport;
        ImGuiWindow* Window; /// Set when the viewport is owned by a window (and ImGuiViewportFlags_CanHostOtherWindows is NOT set)
        int Idx;
        int LastFrameActive; /// Last frame number this viewport was activated by a window
        int LastFocusedStampCount; /// Last stamp number from when a window hosted by this viewport was focused (by comparing this value between two viewport we have an implicit viewport z-order we use as fallback)
        ImGuiID LastNameHash;
        ImVec2 LastPos;
        ImVec2 LastSize;
        float Alpha; /// Window opacity (when dragging dockable windows/viewports we make them transparent)
        float LastAlpha;
        bool LastFocusedHadNavWindow; /// Instead of maintaining a LastFocusedWindow (which may harder to correctly maintain), we merely store weither NavWindow != NULL last time the viewport was focused.
        short PlatformMonitor;
        int[2] BgFgDrawListsLastFrame; /// Last frame number the background (0) and foreground (1) draw lists were used
        ImDrawList*[2] BgFgDrawLists; /// Convenience background (0) and foreground (1) draw lists. We use them to draw software mouser cursor when io.MouseDrawCursor is set and to draw most debug overlays.
        ImDrawData DrawDataP;
        ImDrawDataBuilder DrawDataBuilder; /// Temporary data while building final ImDrawData
        ImVec2 LastPlatformPos;
        ImVec2 LastPlatformSize;
        ImVec2 LastRendererSize;
             /// Per-viewport work area
            /// - Insets are >= 0.0f values, distance from viewport corners to work area.
            /// - BeginMainMenuBar() and DockspaceOverViewport() tend to use work area to avoid stepping over existing contents.
            /// - Generally 'safeAreaInsets' in iOS land, 'DisplayCutout' in Android land.
        ImVec2 WorkInsetMin; /// Work Area inset locked for the frame. GetWorkRect() always fits within GetMainRect().
        ImVec2 WorkInsetMax; /// "
        ImVec2 BuildWorkInsetMin; /// Work Area inset accumulator for current frame, to become next frame's WorkInset
        ImVec2 BuildWorkInsetMax; /// "
    }

    struct ImVec1 {
        float x;
    }

    /// Storage for navigation query/results
    struct ImGuiNavItemData {
        ImGuiWindow* Window; /// Init,Move    /// Best candidate window (result->ItemWindow->RootWindowForNav == request->Window)
        ImGuiID ID; /// Init,Move    /// Best candidate item ID
        ImGuiID FocusScopeId; /// Init,Move    /// Best candidate focus scope ID
        ImRect RectRel; /// Init,Move    /// Best candidate bounding box in window relative space
        ImGuiItemFlags ItemFlags; /// ????,Move    /// Best candidate item flags
        float DistBox; ///      Move    /// Best candidate box distance to current NavId
        float DistCenter; ///      Move    /// Best candidate center distance to current NavId
        float DistAxial; ///      Move    /// Best candidate axial distance to current NavId
        ImGuiSelectionUserData SelectionUserData; //I+Mov    /// Best candidate SetNextItemSelectionUserData() value. Valid if (ItemFlags & ImGuiItemFlags_HasSelectionUserData)
    }

    /// Selection request item
    struct ImGuiSelectionRequest {
         
            //------------------------------------------/// BeginMultiSelect / EndMultiSelect
        ImGuiSelectionRequestType Type; ///  ms:w, app:r     /  ms:w, app:r   /// Request type. You'll most often receive 1 Clear + 1 SetRange with a single-item range.
        bool Selected; ///  ms:w, app:r     /  ms:w, app:r   /// Parameter for SetAll/SetRange requests (true = select, false = unselect)
        ImS8 RangeDirection; ///                  /  ms:w  app:r   /// Parameter for SetRange request: +1 when RangeFirstItem comes before RangeLastItem, -1 otherwise. Useful if you want to preserve selection order on a backward Shift+Click.
        ImGuiSelectionUserData RangeFirstItem; ///                  /  ms:w, app:r   /// Parameter for SetRange request (this is generally == RangeSrcItem when shift selecting from top to bottom).
        ImGuiSelectionUserData RangeLastItem; ///                  /  ms:w, app:r   /// Parameter for SetRange request (this is generally == RangeSrcItem when shift selecting from bottom to top). Inclusive!
    }

    /// Font runtime data for a given size
    /// Important: pointers to ImFontBaked are only valid for the current frame.
    struct ImFontBaked {
         
            /// [Internal] Members: Hot ~20/24 bytes (for CalcTextSize)
        ImVector!(float) IndexAdvanceX; /// 12-16 /// out /// Sparse. Glyphs->AdvanceX in a directly indexable way (cache-friendly for CalcTextSize functions which only this info, and are often bottleneck in large UI).
        float FallbackAdvanceX; /// 4     /// out /// FindGlyph(FallbackChar)->AdvanceX
        float Size; /// 4     /// in  /// Height of characters/line, set during loading (doesn't change after loading)
        float RasterizerDensity; /// 4     /// in  /// Density this is baked at
             /// [Internal] Members: Hot ~28/36 bytes (for RenderText loop)
        ImVector!(ImU16) IndexLookup; /// 12-16 /// out /// Sparse. Index glyphs by Unicode code-point.
        ImVector!(ImFontGlyph) Glyphs; /// 12-16 /// out /// All glyphs.
        int FallbackGlyphIndex; /// 4     /// out /// Index of FontFallbackChar
             /// [Internal] Members: Cold
        float Ascent; /// 4+4   /// out /// Ascent: distance from top to bottom of e.g. 'A' [0..FontSize] (unscaled)
             /// [Internal] Members: Cold
        float Descent; /// 4+4   /// out /// Ascent: distance from top to bottom of e.g. 'A' [0..FontSize] (unscaled)
        uint MetricsTotalSurface; /// 3  /// out /// Total surface in pixels to get an idea of the font rasterization/texture cost (not exact, we approximate the cost of padding between glyphs)
        uint WantDestroy; /// 0  ///     /// Queued for destroy
        uint LockLoadingFallback; /// 0  ///     //
        int LastUsedFrame; /// 4     ///     /// Record of that time this was bounds
        ImGuiID BakedId; /// 4     //
        ImFont* ContainerFont; /// 4-8   /// in  /// Parent font
        void* FontLoaderDatas; /// 4-8   ///     /// Font loader opaque storage (per baked font * sources): single contiguous buffer allocated by imgui, passed to loader.
    }

    /// Hooks and storage for a given font backend.
    /// This structure is likely to evolve as we add support for incremental atlas updates.
    /// Conceptually this could be public, but API is still going to be evolve.
    struct ImFontLoader {
        const(char)* Name;
        bool function(ImFontAtlas* atlas) LoaderInit;
        void function(ImFontAtlas* atlas) LoaderShutdown;
        bool function(ImFontAtlas* atlas,ImFontConfig* src) FontSrcInit;
        void function(ImFontAtlas* atlas,ImFontConfig* src) FontSrcDestroy;
        bool function(ImFontAtlas* atlas,ImFontConfig* src,ImWchar codepoint) FontSrcContainsGlyph;
        bool function(ImFontAtlas* atlas,ImFontConfig* src,ImFontBaked* baked,void* loader_data_for_baked_src) FontBakedInit;
        void function(ImFontAtlas* atlas,ImFontConfig* src,ImFontBaked* baked,void* loader_data_for_baked_src) FontBakedDestroy;
        bool function(ImFontAtlas* atlas,ImFontConfig* src,ImFontBaked* baked,void* loader_data_for_baked_src,ImWchar codepoint,ImFontGlyph* out_glyph) FontBakedLoadGlyph;
             /// Size of backend data, Per Baked * Per Source. Buffers are managed by core to avoid excessive allocations.
            /// FIXME: At this point the two other types of buffers may be managed by core to be consistent?
        size_t FontBakedSrcLoaderDataSize;
    }

    /// Persistent Settings data, stored contiguously in SettingsNodes (sizeof() ~32 bytes)
    struct ImGuiDockNodeSettings {
        ImGuiID ID;
        ImGuiID ParentNodeId;
        ImGuiID ParentWindowId;
        ImGuiID SelectedTabId;
        byte SplitAxis;
        char Depth;
        ImGuiDockNodeFlags Flags; /// NB: We save individual flags one by one in ascii format (ImGuiDockNodeFlags_SavedFlagsMask_)
        ImVec2ih Pos;
        ImVec2ih Size;
        ImVec2ih SizeRef;
    }

    /// Storage data for BeginComboPreview()/EndComboPreview()
    struct ImGuiComboPreviewData {
        ImRect PreviewRect;
        ImVec2 BackupCursorPos;
        ImVec2 BackupCursorMaxPos;
        ImVec2 BackupCursorPosPrevLine;
        float BackupPrevLineTextBaseOffset;
        ImGuiLayoutType BackupLayout;
    }

    /// Helper: ImVec2ih (2D vector, half-size integer, for long-term packed storage)
    struct ImVec2ih {
        short x;
        short y;
    }

    /// Resizing callback data to apply custom constraint. As enabled by SetNextWindowSizeConstraints(). Callback is called during the next Begin().
    /// NB: For basic min/max size constraint on each axis you don't need to use the callback! The SetNextWindowSizeConstraints() parameters are enough.
    struct ImGuiSizeCallbackData {
        void* UserData; /// Read-only.   What user passed to SetNextWindowSizeConstraints(). Generally store an integer or float in here (need reinterpret_cast<>).
        ImVec2 Pos; /// Read-only.   Window position, for reference.
        ImVec2 CurrentSize; /// Read-only.   Current window size.
        ImVec2 DesiredSize; /// Read-write.  Desired size, based on user's mouse position. Write to this field to restrain resizing.
    }

    struct ImGuiShrinkWidthItem {
        int Index;
        float Width;
        float InitialWidth;
    }

    /// Helper: ImRect (2D axis aligned bounding-box)
    /// NB: we can't rely on ImVec2 math operators being available here!
    struct ImRect {
        ImVec2 Min; /// Upper-left
        ImVec2 Max; /// Lower-right
    }

    /// Main IO structure returned by BeginMultiSelect()/EndMultiSelect().
    /// This mainly contains a list of selection requests.
    /// - Use 'Demo->Tools->Debug Log->Selection' to see requests as they happen.
    /// - Some fields are only useful if your list is dynamic and allows deletion (getting post-deletion focus/state right is shown in the demo)
    /// - Below: who reads/writes each fields? 'r'=read, 'w'=write, 'ms'=multi-select code, 'app'=application/user code.
    struct ImGuiMultiSelectIO {
         
            //------------------------------------------/// BeginMultiSelect / EndMultiSelect
        ImVector!(ImGuiSelectionRequest) Requests; ///  ms:w, app:r     /  ms:w  app:r   /// Requests to apply to your selection data.
        ImGuiSelectionUserData RangeSrcItem; ///  ms:w  app:r     /                /// (If using clipper) Begin: Source item (often the first selected item) must never be clipped: use clipper.IncludeItemByIndex() to ensure it is submitted.
        ImGuiSelectionUserData NavIdItem; ///  ms:w, app:r     /                /// (If using deletion) Last known SetNextItemSelectionUserData() value for NavId (if part of submitted items).
        bool NavIdSelected; ///  ms:w, app:r     /        app:r   /// (If using deletion) Last known selection state for NavId (if part of submitted items).
        bool RangeSrcReset; ///        app:w     /  ms:r          /// (If using deletion) Set before EndMultiSelect() to reset ResetSrcItem (e.g. if deleted selection).
        int ItemsCount; ///  ms:w, app:r     /        app:r   /// 'int items_count' parameter to BeginMultiSelect() is copied here for convenience, allowing simpler calls to your ApplyRequests handler. Not used internally.
    }

    struct ImGuiIO {
        ImGuiConfigFlags ConfigFlags; /// = 0              /// See ImGuiConfigFlags_ enum. Set by user/application. Keyboard/Gamepad navigation options, etc.
        ImGuiBackendFlags BackendFlags; /// = 0              /// See ImGuiBackendFlags_ enum. Set by backend (imgui_impl_xxx files or custom backend) to communicate features supported by the backend.
        ImVec2 DisplaySize; /// <unset>          /// Main display size, in pixels (== GetMainViewport()->Size). May change every frame.
        ImVec2 DisplayFramebufferScale; /// = (1, 1)         /// Main display density. For retina display where window coordinates are different from framebuffer coordinates. This will affect font density + will end up in ImDrawData::FramebufferScale.
        float DeltaTime; /// = 1.0f/60.0f     /// Time elapsed since last frame, in seconds. May change every frame.
        float IniSavingRate; /// = 5.0f           /// Minimum time between saving positions/sizes to .ini file, in seconds.
        const(char)* IniFilename; /// = "imgui.ini"    /// Path to .ini file (important: default "imgui.ini" is relative to current working dir!). Set NULL to disable automatic .ini loading/saving or if you want to manually call LoadIniSettingsXXX() / SaveIniSettingsXXX() functions.
        const(char)* LogFilename; /// = "imgui_log.txt"/// Path to .log file (default parameter to ImGui::LogToFile when no file is specified).
        void* UserData; /// = NULL           /// Store your own data.
             /// Font system
        ImFontAtlas* Fonts; /// <auto>           /// Font atlas: load, rasterize and pack one or more fonts into a single texture.
        ImFont* FontDefault; /// = NULL           /// Font to use on NewFrame(). Use NULL to uses Fonts->Fonts[0].
        bool FontAllowUserScaling; /// = false          /// [OBSOLETE] Allow user scaling text of individual window with CTRL+Wheel.
             /// Keyboard/Gamepad Navigation options
        bool ConfigNavSwapGamepadButtons; /// = false          /// Swap Activate<>Cancel (A<>B) buttons, matching typical "Nintendo/Japanese style" gamepad layout.
        bool ConfigNavMoveSetMousePos; /// = false          /// Directional/tabbing navigation teleports the mouse cursor. May be useful on TV/console systems where moving a virtual mouse is difficult. Will update io.MousePos and set io.WantSetMousePos=true.
        bool ConfigNavCaptureKeyboard; /// = true           /// Sets io.WantCaptureKeyboard when io.NavActive is set.
        bool ConfigNavEscapeClearFocusItem; /// = true           /// Pressing Escape can clear focused item + navigation id/highlight. Set to false if you want to always keep highlight on.
        bool ConfigNavEscapeClearFocusWindow; /// = false          /// Pressing Escape can clear focused window as well (super set of io.ConfigNavEscapeClearFocusItem).
        bool ConfigNavCursorVisibleAuto; /// = true           /// Using directional navigation key makes the cursor visible. Mouse click hides the cursor.
        bool ConfigNavCursorVisibleAlways; /// = false          /// Navigation cursor is always visible.
             /// Docking options (when ImGuiConfigFlags_DockingEnable is set)
        bool ConfigDockingNoSplit; /// = false          /// Simplified docking mode: disable window splitting, so docking is limited to merging multiple windows together into tab-bars.
        bool ConfigDockingWithShift; /// = false          /// Enable docking with holding Shift key (reduce visual noise, allows dropping in wider space)
        bool ConfigDockingAlwaysTabBar; /// = false          /// [BETA] [FIXME: This currently creates regression with auto-sizing and general overhead] Make every single floating window display within a docking node.
        bool ConfigDockingTransparentPayload; /// = false          /// [BETA] Make window or viewport transparent when docking and only display docking boxes on the target viewport. Useful if rendering of multiple viewport cannot be synced. Best used with ConfigViewportsNoAutoMerge.
             /// Viewport options (when ImGuiConfigFlags_ViewportsEnable is set)
        bool ConfigViewportsNoAutoMerge; /// = false;         /// Set to make all floating imgui windows always create their own viewport. Otherwise, they are merged into the main host viewports when overlapping it. May also set ImGuiViewportFlags_NoAutoMerge on individual viewport.
        bool ConfigViewportsNoTaskBarIcon; /// = false          /// Disable default OS task bar icon flag for secondary viewports. When a viewport doesn't want a task bar icon, ImGuiViewportFlags_NoTaskBarIcon will be set on it.
        bool ConfigViewportsNoDecoration; /// = true           /// Disable default OS window decoration flag for secondary viewports. When a viewport doesn't want window decorations, ImGuiViewportFlags_NoDecoration will be set on it. Enabling decoration can create subsequent issues at OS levels (e.g. minimum window size).
        bool ConfigViewportsNoDefaultParent; /// = false          /// Disable default OS parenting to main viewport for secondary viewports. By default, viewports are marked with ParentViewportId = <main_viewport>, expecting the platform backend to setup a parent/child relationship between the OS windows (some backend may ignore this). Set to true if you want the default to be 0, then all viewports will be top-level OS windows.
             /// DPI/Scaling options
            /// This may keep evolving during 1.92.x releases. Expect some turbulence.
        bool ConfigDpiScaleFonts; /// = false          /// [EXPERIMENTAL] Automatically overwrite style.FontScaleDpi when Monitor DPI changes. This will scale fonts but _NOT_ scale sizes/padding for now.
        bool ConfigDpiScaleViewports; /// = false          /// [EXPERIMENTAL] Scale Dear ImGui and Platform Windows when Monitor DPI changes.
             /// Miscellaneous options
            /// (you can visualize and interact with all options in 'Demo->Configuration')
        bool MouseDrawCursor; /// = false          /// Request ImGui to draw a mouse cursor for you (if you are on a platform without a mouse cursor). Cannot be easily renamed to 'io.ConfigXXX' because this is frequently used by backend implementations.
        bool ConfigMacOSXBehaviors; /// = defined(__APPLE__) /// Swap Cmd<>Ctrl keys + OS X style text editing cursor movement using Alt instead of Ctrl, Shortcuts using Cmd/Super instead of Ctrl, Line/Text Start and End using Cmd+Arrows instead of Home/End, Double click selects by word instead of selecting whole text, Multi-selection in lists uses Cmd/Super instead of Ctrl.
        bool ConfigInputTrickleEventQueue; /// = true           /// Enable input queue trickling: some types of events submitted during the same frame (e.g. button down + up) will be spread over multiple frames, improving interactions with low framerates.
        bool ConfigInputTextCursorBlink; /// = true           /// Enable blinking cursor (optional as some users consider it to be distracting).
        bool ConfigInputTextEnterKeepActive; /// = false          /// [BETA] Pressing Enter will keep item active and select contents (single-line only).
        bool ConfigDragClickToInputText; /// = false          /// [BETA] Enable turning DragXXX widgets into text input with a simple mouse click-release (without moving). Not desirable on devices without a keyboard.
        bool ConfigWindowsResizeFromEdges; /// = true           /// Enable resizing of windows from their edges and from the lower-left corner. This requires ImGuiBackendFlags_HasMouseCursors for better mouse cursor feedback. (This used to be a per-window ImGuiWindowFlags_ResizeFromAnySide flag)
        bool ConfigWindowsMoveFromTitleBarOnly; /// = false      /// Enable allowing to move windows only when clicking on their title bar. Does not apply to windows without a title bar.
        bool ConfigWindowsCopyContentsWithCtrlC; /// = false      /// [EXPERIMENTAL] CTRL+C copy the contents of focused window into the clipboard. Experimental because: (1) has known issues with nested Begin/End pairs (2) text output quality varies (3) text output is in submission order rather than spatial order.
        bool ConfigScrollbarScrollByPage; /// = true           /// Enable scrolling page by page when clicking outside the scrollbar grab. When disabled, always scroll to clicked location. When enabled, Shift+Click scrolls to clicked location.
        float ConfigMemoryCompactTimer; /// = 60.0f          /// Timer (in seconds) to free transient windows/tables memory buffers when unused. Set to -1.0f to disable.
             /// Inputs Behaviors
            /// (other variables, ones which are expected to be tweaked within UI code, are exposed in ImGuiStyle)
        float MouseDoubleClickTime; /// = 0.30f          /// Time for a double-click, in seconds.
        float MouseDoubleClickMaxDist; /// = 6.0f           /// Distance threshold to stay in to validate a double-click, in pixels.
        float MouseDragThreshold; /// = 6.0f           /// Distance threshold before considering we are dragging.
        float KeyRepeatDelay; /// = 0.275f         /// When holding a key/button, time before it starts repeating, in seconds (for buttons in Repeat mode, etc.).
        float KeyRepeatRate; /// = 0.050f         /// When holding a key/button, rate at which it repeats, in seconds.
             /// Options to configure Error Handling and how we handle recoverable errors [EXPERIMENTAL]
            /// - Error recovery is provided as a way to facilitate:
            ///    - Recovery after a programming error (native code or scripting language - the later tends to facilitate iterating on code while running).
            ///    - Recovery after running an exception handler or any error processing which may skip code after an error has been detected.
            /// - Error recovery is not perfect nor guaranteed! It is a feature to ease development.
            ///   You not are not supposed to rely on it in the course of a normal application run.
            /// - Functions that support error recovery are using IM_ASSERT_USER_ERROR() instead of IM_ASSERT().
            /// - By design, we do NOT allow error recovery to be 100% silent. One of the three options needs to be checked!
            /// - Always ensure that on programmers seats you have at minimum Asserts or Tooltips enabled when making direct imgui API calls!
            ///   Otherwise it would severely hinder your ability to catch and correct mistakes!
            /// Read https://github.com/ocornut/imgui/wiki/Error-Handling for details.
            /// - Programmer seats: keep asserts (default), or disable asserts and keep error tooltips (new and nice!)
            /// - Non-programmer seats: maybe disable asserts, but make sure errors are resurfaced (tooltips, visible log entries, use callback etc.)
            /// - Recovery after error/exception: record stack sizes with ErrorRecoveryStoreState(), disable assert, set log callback (to e.g. trigger high-level breakpoint), recover with ErrorRecoveryTryToRecoverState(), restore settings.
        bool ConfigErrorRecovery; /// = true       /// Enable error recovery support. Some errors won't be detected and lead to direct crashes if recovery is disabled.
        bool ConfigErrorRecoveryEnableAssert; /// = true       /// Enable asserts on recoverable error. By default call IM_ASSERT() when returning from a failing IM_ASSERT_USER_ERROR()
        bool ConfigErrorRecoveryEnableDebugLog; /// = true       /// Enable debug log output on recoverable errors.
        bool ConfigErrorRecoveryEnableTooltip; /// = true       /// Enable tooltip on recoverable errors. The tooltip include a way to enable asserts if they were disabled.
             /// Option to enable various debug tools showing buttons that will call the IM_DEBUG_BREAK() macro.
            /// - The Item Picker tool will be available regardless of this being enabled, in order to maximize its discoverability.
            /// - Requires a debugger being attached, otherwise IM_DEBUG_BREAK() options will appear to crash your application.
            ///   e.g. io.ConfigDebugIsDebuggerPresent = ::IsDebuggerPresent() on Win32, or refer to ImOsIsDebuggerPresent() imgui_test_engine/imgui_te_utils.cpp for a Unix compatible version).
        bool ConfigDebugIsDebuggerPresent; /// = false          /// Enable various tools calling IM_DEBUG_BREAK().
             /// Tools to detect code submitting items with conflicting/duplicate IDs
            /// - Code should use PushID()/PopID() in loops, or append "##xx" to same-label identifiers.
            /// - Empty label e.g. Button("") == same ID as parent widget/node. Use Button("##xx") instead!
            /// - See FAQ https://github.com/ocornut/imgui/blob/master/docs/FAQ.md#q-about-the-id-stack-system
        bool ConfigDebugHighlightIdConflicts; /// = true           /// Highlight and show an error message popup when multiple items have conflicting identifiers.
        bool ConfigDebugHighlightIdConflictsShowItemPicker; //=true /// Show "Item Picker" button in aforementioned popup.
             /// Tools to test correct Begin/End and BeginChild/EndChild behaviors.
            /// - Presently Begin()/End() and BeginChild()/EndChild() needs to ALWAYS be called in tandem, regardless of return value of BeginXXX()
            /// - This is inconsistent with other BeginXXX functions and create confusion for many users.
            /// - We expect to update the API eventually. In the meanwhile we provide tools to facilitate checking user-code behavior.
        bool ConfigDebugBeginReturnValueOnce; /// = false          /// First-time calls to Begin()/BeginChild() will return false. NEEDS TO BE SET AT APPLICATION BOOT TIME if you don't want to miss windows.
        bool ConfigDebugBeginReturnValueLoop; /// = false          /// Some calls to Begin()/BeginChild() will return false. Will cycle through window depths then repeat. Suggested use: add "io.ConfigDebugBeginReturnValue = io.KeyShift" in your main loop then occasionally press SHIFT. Windows should be flickering while running.
             /// Option to deactivate io.AddFocusEvent(false) handling.
            /// - May facilitate interactions with a debugger when focus loss leads to clearing inputs data.
            /// - Backends may have other side-effects on focus loss, so this will reduce side-effects but not necessary remove all of them.
        bool ConfigDebugIgnoreFocusLoss; /// = false          /// Ignore io.AddFocusEvent(false), consequently not calling io.ClearInputKeys()/io.ClearInputMouse() in input processing.
             /// Option to audit .ini data
        bool ConfigDebugIniSettings; /// = false          /// Save .ini data with extra comments (particularly helpful for Docking, but makes saving slower)
             /// Nowadays those would be stored in ImGuiPlatformIO but we are leaving them here for legacy reasons.
            /// Optional: Platform/Renderer backend name (informational only! will be displayed in About Window) + User data for backend/wrappers to store their own stuff.
        const(char)* BackendPlatformName; /// = NULL
        const(char)* BackendRendererName; /// = NULL
        void* BackendPlatformUserData; /// = NULL           /// User data for platform backend
        void* BackendRendererUserData; /// = NULL           /// User data for renderer backend
        void* BackendLanguageUserData; /// = NULL           /// User data for non C++ programming language backend
        bool WantCaptureMouse; /// Set when Dear ImGui will use mouse inputs, in this case do not dispatch them to your main game/application (either way, always pass on mouse inputs to imgui). (e.g. unclicked mouse is hovering over an imgui window, widget is active, mouse was clicked over an imgui window, etc.).
        bool WantCaptureKeyboard; /// Set when Dear ImGui will use keyboard inputs, in this case do not dispatch them to your main game/application (either way, always pass keyboard inputs to imgui). (e.g. InputText active, or an imgui window is focused and navigation is enabled, etc.).
        bool WantTextInput; /// Mobile/console: when set, you may display an on-screen keyboard. This is set by Dear ImGui when it wants textual keyboard input to happen (e.g. when a InputText widget is active).
        bool WantSetMousePos; /// MousePos has been altered, backend should reposition mouse on next frame. Rarely used! Set only when io.ConfigNavMoveSetMousePos is enabled.
        bool WantSaveIniSettings; /// When manual .ini load/save is active (io.IniFilename == NULL), this will be set to notify your application that you can call SaveIniSettingsToMemory() and save yourself. Important: clear io.WantSaveIniSettings yourself after saving!
        bool NavActive; /// Keyboard/Gamepad navigation is currently allowed (will handle ImGuiKey_NavXXX events) = a window is focused and it doesn't use the ImGuiWindowFlags_NoNavInputs flag.
        bool NavVisible; /// Keyboard/Gamepad navigation highlight is visible and allowed (will handle ImGuiKey_NavXXX events).
        float Framerate; /// Estimate of application framerate (rolling average over 60 frames, based on io.DeltaTime), in frame per second. Solely for convenience. Slow applications may not want to use a moving average or may want to reset underlying buffers occasionally.
        int MetricsRenderVertices; /// Vertices output during last call to Render()
        int MetricsRenderIndices; /// Indices output during last call to Render() = number of triangles * 3
        int MetricsRenderWindows; /// Number of visible windows
        int MetricsActiveWindows; /// Number of active windows
        ImVec2 MouseDelta; /// Mouse delta. Note that this is zero if either current or previous position are invalid (-FLT_MAX,-FLT_MAX), so a disappearing/reappearing mouse won't have a huge delta.
        ImGuiContext* Ctx; /// Parent UI context (needs to be set explicitly by parent).
             /// Main Input State
            /// (this block used to be written by backend, since 1.87 it is best to NOT write to those directly, call the AddXXX functions above instead)
            /// (reading from those variables is fair game, as they are extremely unlikely to be moving anywhere)
        ImVec2 MousePos; /// Mouse position, in pixels. Set to ImVec2(-FLT_MAX, -FLT_MAX) if mouse is unavailable (on another screen, etc.)
        bool[5] MouseDown; /// Mouse buttons: 0=left, 1=right, 2=middle + extras (ImGuiMouseButton_COUNT == 5). Dear ImGui mostly uses left and right buttons. Other buttons allow us to track if the mouse is being used by your application + available to user as a convenience via IsMouse** API.
        float MouseWheel; /// Mouse wheel Vertical: 1 unit scrolls about 5 lines text. >0 scrolls Up, <0 scrolls Down. Hold SHIFT to turn vertical scroll into horizontal scroll.
        float MouseWheelH; /// Mouse wheel Horizontal. >0 scrolls Left, <0 scrolls Right. Most users don't have a mouse with a horizontal wheel, may not be filled by all backends.
        ImGuiMouseSource MouseSource; /// Mouse actual input peripheral (Mouse/TouchScreen/Pen).
        ImGuiID MouseHoveredViewport; /// (Optional) Modify using io.AddMouseViewportEvent(). With multi-viewports: viewport the OS mouse is hovering. If possible _IGNORING_ viewports with the ImGuiViewportFlags_NoInputs flag is much better (few backends can handle that). Set io.BackendFlags |= ImGuiBackendFlags_HasMouseHoveredViewport if you can provide this info. If you don't imgui will infer the value using the rectangles and last focused time of the viewports it knows about (ignoring other OS windows).
        bool KeyCtrl; /// Keyboard modifier down: Control
        bool KeyShift; /// Keyboard modifier down: Shift
        bool KeyAlt; /// Keyboard modifier down: Alt
        bool KeySuper; /// Keyboard modifier down: Cmd/Super/Windows
             /// Other state maintained from data above + IO function calls
        ImGuiKeyChord KeyMods; /// Key mods flags (any of ImGuiMod_Ctrl/ImGuiMod_Shift/ImGuiMod_Alt/ImGuiMod_Super flags, same as io.KeyCtrl/KeyShift/KeyAlt/KeySuper but merged into flags. Read-only, updated by NewFrame()
        ImGuiKeyData[ImGuiKey.NamedKey_COUNT] KeysData; /// Key state for all known keys. Use IsKeyXXX() functions to access this.
        bool WantCaptureMouseUnlessPopupClose; /// Alternative to WantCaptureMouse: (WantCaptureMouse == true && WantCaptureMouseUnlessPopupClose == false) when a click over void is expected to close a popup.
        ImVec2 MousePosPrev; /// Previous mouse position (note that MouseDelta is not necessary == MousePos-MousePosPrev, in case either position is invalid)
        ImVec2[5] MouseClickedPos; /// Position at time of clicking
        double[5] MouseClickedTime; /// Time of last click (used to figure out double-click)
        bool[5] MouseClicked; /// Mouse button went from !Down to Down (same as MouseClickedCount[x] != 0)
        bool[5] MouseDoubleClicked; /// Has mouse button been double-clicked? (same as MouseClickedCount[x] == 2)
        ImU16[5] MouseClickedCount; /// == 0 (not clicked), == 1 (same as MouseClicked[]), == 2 (double-clicked), == 3 (triple-clicked) etc. when going from !Down to Down
        ImU16[5] MouseClickedLastCount; /// Count successive number of clicks. Stays valid after mouse release. Reset after another click is done.
        bool[5] MouseReleased; /// Mouse button went from Down to !Down
        double[5] MouseReleasedTime; /// Time of last released (rarely used! but useful to handle delayed single-click when trying to disambiguate them from double-click).
        bool[5] MouseDownOwned; /// Track if button was clicked inside a dear imgui window or over void blocked by a popup. We don't request mouse capture from the application if click started outside ImGui bounds.
        bool[5] MouseDownOwnedUnlessPopupClose; /// Track if button was clicked inside a dear imgui window.
        bool MouseWheelRequestAxisSwap; /// On a non-Mac system, holding SHIFT requests WheelY to perform the equivalent of a WheelX event. On a Mac system this is already enforced by the system.
        bool MouseCtrlLeftAsRightClick; /// (OSX) Set to true when the current click was a Ctrl+click that spawned a simulated right click
        float[5] MouseDownDuration; /// Duration the mouse button has been down (0.0f == just clicked)
        float[5] MouseDownDurationPrev; /// Previous time the mouse button has been down
        ImVec2[5] MouseDragMaxDistanceAbs; /// Maximum distance, absolute, on each axis, of how much mouse has traveled from the clicking point
        float[5] MouseDragMaxDistanceSqr; /// Squared maximum distance of how much mouse has traveled from the clicking point (used for moving thresholds)
        float PenPressure; /// Touch/Pen pressure (0.0f to 1.0f, should be >0.0f only when MouseDown[0] == true). Helper storage currently unused by Dear ImGui.
        bool AppFocusLost; /// Only modify via AddFocusEvent()
        bool AppAcceptingEvents; /// Only modify via SetAppAcceptingEvents()
        ImWchar16 InputQueueSurrogate; /// For AddInputCharacterUTF16()
        ImVector!(ImWchar) InputQueueCharacters; /// Queue of _characters_ input (obtained by platform backend). Fill using AddInputCharacter() helper.
    }

    /// Per-instance data that needs preserving across frames (seemingly most others do not need to be preserved aside from debug needs. Does that means they could be moved to ImGuiTableTempData?)
    /// sizeof() ~ 24 bytes
    struct ImGuiTableInstanceData {
        ImGuiID TableInstanceID;
        float LastOuterHeight; /// Outer height from last frame
        float LastTopHeadersRowHeight; /// Height of first consecutive header rows from last frame (FIXME: this is used assuming consecutive headers are in same frozen set)
        float LastFrozenHeight; /// Height of frozen section from last frame
        int HoveredRowLast; /// Index of row which was hovered last frame.
        int HoveredRowNext; /// Index of row hovered this frame, set after encountering it.
    }

    struct ImTextureRef {
             /// Members (either are set, never both!)
        ImTextureData* _TexData; ///      A texture, generally owned by a ImFontAtlas. Will convert to ImTextureID during render loop, after texture has been uploaded.
        ImTextureID _TexID; /// _OR_ Low-level backend texture identifier, if already uploaded or created by user/app. Generally provided to e.g. ImGui::Image() calls.
    }

    /// Data payload for Drag and Drop operations: AcceptDragDropPayload(), GetDragDropPayload()
    struct ImGuiPayload {
         
            /// Members
        void* Data; /// Data (copied and owned by dear imgui)
        int DataSize; /// Data size
             /// [Internal]
        ImGuiID SourceId; /// Source item id
        ImGuiID SourceParentId; /// Source parent id (if available)
        int DataFrameCount; /// Data timestamp
        char[32+1] DataType; /// Data type tag (short user-supplied string, 32 characters max)
        bool Preview; /// Set when AcceptDragDropPayload() was called and mouse has been hovering the target item (nb: handle overlapping drag targets)
        bool Delivery; /// Set when AcceptDragDropPayload() was called and mouse button is released over the target item.
    }

    /// Helper: ImBitVector
    /// Store 1-bit per value.
    struct ImBitVector {
        ImVector!(ImU32) Storage;
    }

    struct ImGuiInputEventKey {
        ImGuiKey Key;
        bool Down;
        float AnalogValue;
    }

    /// Stacked color modifier, backup of modified data so we can restore it
    struct ImGuiColorMod {
        ImGuiCol Col;
        ImVec4 BackupValue;
    }

    /// Shared state of InputText(), passed as an argument to your callback when a ImGuiInputTextFlags_Callback* flag is used.
    /// The callback function should return 0 by default.
    /// Callbacks (follow a flag name and see comments in ImGuiInputTextFlags_ declarations for more details)
    /// - ImGuiInputTextFlags_CallbackEdit:        Callback on buffer edit. Note that InputText() already returns true on edit + you can always use IsItemEdited(). The callback is useful to manipulate the underlying buffer while focus is active.
    /// - ImGuiInputTextFlags_CallbackAlways:      Callback on each iteration
    /// - ImGuiInputTextFlags_CallbackCompletion:  Callback on pressing TAB
    /// - ImGuiInputTextFlags_CallbackHistory:     Callback on pressing Up/Down arrows
    /// - ImGuiInputTextFlags_CallbackCharFilter:  Callback on character inputs to replace or discard them. Modify 'EventChar' to replace or discard, or return 1 in callback to discard.
    /// - ImGuiInputTextFlags_CallbackResize:      Callback on buffer capacity changes request (beyond 'buf_size' parameter value), allowing the string to grow.
    struct ImGuiInputTextCallbackData {
        ImGuiContext* Ctx; /// Parent UI context
        ImGuiInputTextFlags EventFlag; /// One ImGuiInputTextFlags_Callback*    /// Read-only
        ImGuiInputTextFlags Flags; /// What user passed to InputText()      /// Read-only
        void* UserData; /// What user passed to InputText()      /// Read-only
             /// Arguments for the different callback events
            /// - During Resize callback, Buf will be same as your input buffer.
            /// - However, during Completion/History/Always callback, Buf always points to our own internal data (it is not the same as your buffer)! Changes to it will be reflected into your own buffer shortly after the callback.
            /// - To modify the text buffer in a callback, prefer using the InsertChars() / DeleteChars() function. InsertChars() will take care of calling the resize callback if necessary.
            /// - If you know your edits are not going to resize the underlying buffer allocation, you may modify the contents of 'Buf[]' directly. You need to update 'BufTextLen' accordingly (0 <= BufTextLen < BufSize) and set 'BufDirty'' to true so InputText can update its internal state.
        ImWchar EventChar; /// Character input                      /// Read-write   /// [CharFilter] Replace character with another one, or set to zero to drop. return 1 is equivalent to setting EventChar=0;
        ImGuiKey EventKey; /// Key pressed (Up/Down/TAB)            /// Read-only    /// [Completion,History]
        char* Buf; /// Text buffer                          /// Read-write   /// [Resize] Can replace pointer / [Completion,History,Always] Only write to pointed data, don't replace the actual pointer!
        int BufTextLen; /// Text length (in bytes)               /// Read-write   /// [Resize,Completion,History,Always] Exclude zero-terminator storage. In C land: == strlen(some_text), in C++ land: string.length()
        int BufSize; /// Buffer size (in bytes) = capacity+1  /// Read-only    /// [Resize,Completion,History,Always] Include zero-terminator storage. In C land == ARRAYSIZE(my_char_array), in C++ land: string.capacity()+1
        bool BufDirty; /// Set if you modify Buf/BufTextLen!    /// Write        /// [Completion,History,Always]
        int CursorPos; ///                                      /// Read-write   /// [Completion,History,Always]
        int SelectionStart; ///                                      /// Read-write   /// [Completion,History,Always] == to SelectionEnd when no selection)
        int SelectionEnd; ///                                      /// Read-write   /// [Completion,History,Always]
    }

    struct ImGuiInputEventAppFocused {
        bool Focused;
    }

    /// Transient cell data stored per row.
    /// sizeof() ~ 6 bytes
    struct ImGuiTableCellData {
        ImU32 BgColor; /// Actual color
        ImGuiTableColumnIdx Column; /// Column number
    }

    /// A font input/source (we may rename this to ImFontSource in the future)
    struct ImFontConfig {
         
            /// Data Source
        char[40] Name; /// <auto>   /// Name (strictly to ease debugging, hence limited size buffer)
        void* FontData; ///          /// TTF/OTF data
        int FontDataSize; ///          /// TTF/OTF data size
        bool FontDataOwnedByAtlas; /// true     /// TTF/OTF data ownership taken by the container ImFontAtlas (will delete memory itself).
             /// Options
        bool MergeMode; /// false    /// Merge into previous ImFont, so you can combine multiple inputs font into one ImFont (e.g. ASCII font + icons + Japanese glyphs). You may want to use GlyphOffset.y when merge font of different heights.
        bool PixelSnapH; /// false    /// Align every glyph AdvanceX to pixel boundaries. Useful e.g. if you are merging a non-pixel aligned font with the default font. If enabled, you can set OversampleH/V to 1.
        bool PixelSnapV; /// true     /// Align Scaled GlyphOffset.y to pixel boundaries.
        ImS8 FontNo; /// 0        /// Index of font within TTF/OTF file
        ImS8 OversampleH; /// 0 (2)    /// Rasterize at higher quality for sub-pixel positioning. 0 == auto == 1 or 2 depending on size. Note the difference between 2 and 3 is minimal. You can reduce this to 1 for large glyphs save memory. Read https://github.com/nothings/stb/blob/master/tests/oversample/README.md for details.
        ImS8 OversampleV; /// 0 (1)    /// Rasterize at higher quality for sub-pixel positioning. 0 == auto == 1. This is not really useful as we don't use sub-pixel positions on the Y axis.
        float SizePixels; ///          /// Size in pixels for rasterizer (more or less maps to the resulting font height).
        const(ImWchar)* GlyphRanges; /// NULL     /// *LEGACY* THE ARRAY DATA NEEDS TO PERSIST AS LONG AS THE FONT IS ALIVE. Pointer to a user-provided list of Unicode range (2 value per range, values are inclusive, zero-terminated list).
        const(ImWchar)* GlyphExcludeRanges; /// NULL     /// Pointer to a VERY SHORT user-provided list of Unicode range (2 value per range, values are inclusive, zero-terminated list). This is very close to GlyphRanges[] but designed to exclude ranges from a font source, when merging fonts with overlapping glyphs. Use "Input Glyphs Overlap Detection Tool" to find about your overlapping ranges.
         
            //ImVec2        GlyphExtraSpacing;      /// 0, 0     /// (REMOVED AT IT SEEMS LARGELY OBSOLETE. PLEASE REPORT IF YOU WERE USING THIS). Extra spacing (in pixels) between glyphs when rendered: essentially add to glyph->AdvanceX. Only X axis is supported for now.
        ImVec2 GlyphOffset; /// 0, 0     /// Offset (in pixels) all glyphs from this font input. Absolute value for default size, other sizes will scale this value.
        float GlyphMinAdvanceX; /// 0        /// Minimum AdvanceX for glyphs, set Min to align font icons, set both Min/Max to enforce mono-space font. Absolute value for default size, other sizes will scale this value.
        float GlyphMaxAdvanceX; /// FLT_MAX  /// Maximum AdvanceX for glyphs
        float GlyphExtraAdvanceX; /// 0        /// Extra spacing (in pixels) between glyphs. Please contact us if you are using this. /// FIXME-NEWATLAS: Intentionally unscaled
        uint FontLoaderFlags; /// 0        /// Settings for custom font builder. THIS IS BUILDER IMPLEMENTATION DEPENDENT. Leave as zero if unsure.
         
            //unsigned int  FontBuilderFlags;       /// --       /// [Renamed in 1.92] Ue FontLoaderFlags.
        float RasterizerMultiply; /// 1.0f     /// Linearly brighten (>1.0f) or darken (<1.0f) font output. Brightening small fonts may be a good workaround to make them more readable. This is a silly thing we may remove in the future.
        float RasterizerDensity; /// 1.0f     /// [LEGACY: this only makes sense when ImGuiBackendFlags_RendererHasTextures is not supported] DPI scale multiplier for rasterization. Not altering other font metrics: makes it easy to swap between e.g. a 100% and a 400% fonts for a zooming display, or handle Retina screen. IMPORTANT: If you change this it is expected that you increase/decrease font scale roughly to the inverse of this, otherwise quality may look lowered.
        ImWchar EllipsisChar; /// 0        /// Explicitly specify Unicode codepoint of ellipsis character. When fonts are being merged first specified ellipsis will be used.
             /// [Internal]
        ImFontFlags Flags; /// Font flags (don't use just yet, will be exposed in upcoming 1.92.X updates)
        ImFont* DstFont; /// Target font (as we merging fonts, multiple ImFontConfig may target the same font)
        const(ImFontLoader)* FontLoader; /// Custom font backend for this source (other use one stored in ImFontAtlas)
        void* FontLoaderData; /// Font loader opaque storage (per font config)
    }

    /// Status storage for the last submitted item
    struct ImGuiLastItemData {
        ImGuiID ID;
        ImGuiItemFlags ItemFlags; /// See ImGuiItemFlags_ (called 'InFlags' before v1.91.4).
        ImGuiItemStatusFlags StatusFlags; /// See ImGuiItemStatusFlags_
        ImRect Rect; /// Full rectangle
        ImRect NavRect; /// Navigation scoring rectangle (not displayed)
         
            /// Rarely used fields are not explicitly cleared, only valid when the corresponding ImGuiItemStatusFlags are set.
        ImRect DisplayRect; /// Display rectangle. ONLY VALID IF (StatusFlags & ImGuiItemStatusFlags_HasDisplayRect) is set.
        ImRect ClipRect; /// Clip rectangle at the time of submitting item. ONLY VALID IF (StatusFlags & ImGuiItemStatusFlags_HasClipRect) is set..
        ImGuiKeyChord Shortcut; /// Shortcut at the time of submitting item. ONLY VALID IF (StatusFlags & ImGuiItemStatusFlags_HasShortcut) is set..
    }

    /// [Internal] For use by ImDrawList
    struct ImDrawCmdHeader {
        ImVec4 ClipRect;
        ImTextureRef TexRef;
        uint VtxOffset;
    }

    /// Data shared between all ImDrawList instances
    /// Conceptually this could have been called e.g. ImDrawListSharedContext
    /// Typically one ImGui context would create and maintain one of this.
    /// You may want to create your own instance of you try to ImDrawList completely without ImGui. In that case, watch out for future changes to this structure.
    struct ImDrawListSharedData {
        ImVec2 TexUvWhitePixel; /// UV of white pixel in the atlas (== FontAtlas->TexUvWhitePixel)
        const(ImVec4)* TexUvLines; /// UV of anti-aliased lines in the atlas (== FontAtlas->TexUvLines)
        ImFontAtlas* FontAtlas; /// Current font atlas
        ImFont* Font; /// Current font (used for simplified AddText overload)
        float FontSize; /// Current font size (used for for simplified AddText overload)
        float FontScale; /// Current font scale (== FontSize / Font->FontSize)
        float CurveTessellationTol; /// Tessellation tolerance when using PathBezierCurveTo()
        float CircleSegmentMaxError; /// Number of circle segments to use per pixel of radius for AddCircle() etc
        float InitialFringeScale; /// Initial scale to apply to AA fringe
        ImDrawListFlags InitialFlags; /// Initial flags at the beginning of the frame (it is possible to alter flags on a per-drawlist basis afterwards)
        ImVec4 ClipRectFullscreen; /// Value for PushClipRectFullscreen()
        ImVector!(ImVec2) TempBuffer; /// Temporary write buffer
        ImVector!(ImDrawList*) DrawLists; /// All draw lists associated to this ImDrawListSharedData
        ImGuiContext* Context; /// [OPTIONAL] Link to Dear ImGui context. 99% of ImDrawList/ImFontAtlas can function without an ImGui context, but this facilitate handling one legacy edge case.
             /// Lookup tables
        ImVec2[48] ArcFastVtx; /// Sample points on the quarter of the circle.
        float ArcFastRadiusCutoff; /// Cutoff radius after which arc drawing will fallback to slower PathArcTo()
        ImU8[64] CircleSegmentCounts; /// Precomputed segment count for given radius before we calculate it dynamically (to avoid calculation overhead)
    }

    struct ImGuiDebugAllocInfo {
        int TotalAllocCount; /// Number of call to MemAlloc().
        int TotalFreeCount;
        ImS16 LastEntriesIdx; /// Current index in buffer
        ImGuiDebugAllocEntry[6] LastEntriesBuf; /// Track last 6 frames that had allocations
    }

    /// All draw data to render a Dear ImGui frame
    /// (NB: the style and the naming convention here is a little inconsistent, we currently preserve them for backward compatibility purpose,
    /// as this is one of the oldest structure exposed by the library! Basically, ImDrawList == CmdList)
    struct ImDrawData {
        bool Valid; /// Only valid after Render() is called and before the next NewFrame() is called.
        int CmdListsCount; /// Number of ImDrawList* to render. (== CmdLists.Size). Exists for legacy reason.
        int TotalIdxCount; /// For convenience, sum of all ImDrawList's IdxBuffer.Size
        int TotalVtxCount; /// For convenience, sum of all ImDrawList's VtxBuffer.Size
        ImVector!(ImDrawList*) CmdLists; /// Array of ImDrawList* to render. The ImDrawLists are owned by ImGuiContext and only pointed to from here.
        ImVec2 DisplayPos; /// Top-left position of the viewport to render (== top-left of the orthogonal projection matrix to use) (== GetMainViewport()->Pos for the main viewport, == (0.0) in most single-viewport applications)
        ImVec2 DisplaySize; /// Size of the viewport to render (== GetMainViewport()->Size for the main viewport, == io.DisplaySize in most single-viewport applications)
        ImVec2 FramebufferScale; /// Amount of pixels for each unit of DisplaySize. Copied from viewport->FramebufferScale (== io.DisplayFramebufferScale for main viewport). Generally (1,1) on normal display, (2,2) on OSX with Retina display.
        ImGuiViewport* OwnerViewport; /// Viewport carrying the ImDrawData instance, might be of use to the renderer (generally not).
        ImVector!(ImTextureData*)* Textures; /// List of textures to update. Most of the times the list is shared by all ImDrawData, has only 1 texture and it doesn't need any update. This almost always points to ImGui::GetPlatformIO().Textures[]. May be overriden or set to NULL if you want to manually update textures.
    }

    /// Internal state of the currently focused/edited text input box
    /// For a given item ID, access with ImGui::GetInputTextState()
    struct ImGuiInputTextState {
        ImGuiContext* Ctx; /// parent UI context (needs to be set explicitly by parent).
        ImStbTexteditState* Stb; /// State for stb_textedit.h
        ImGuiInputTextFlags Flags; /// copy of InputText() flags. may be used to check if e.g. ImGuiInputTextFlags_Password is set.
        ImGuiID ID; /// widget id owning the text state
        int TextLen; /// UTF-8 length of the string in TextA (in bytes)
        const(char)* TextSrc; /// == TextA.Data unless read-only, in which case == buf passed to InputText(). Field only set and valid _inside_ the call InputText() call.
        ImVector!(char) TextA; /// main UTF8 buffer. TextA.Size is a buffer size! Should always be >= buf_size passed by user (and of course >= CurLenA + 1).
        ImVector!(char) TextToRevertTo; /// value to revert to when pressing Escape = backup of end-user buffer at the time of focus (in UTF-8, unaltered)
        ImVector!(char) CallbackTextBackup; /// temporary storage for callback to support automatic reconcile of undo-stack
        int BufCapacity; /// end-user buffer capacity (include zero terminator)
        ImVec2 Scroll; /// horizontal offset (managed manually) + vertical scrolling (pulled from child window's own Scroll.y)
        float CursorAnim; /// timer for cursor blink, reset on every user action so the cursor reappears immediately
        bool CursorFollow; /// set when we want scrolling to follow the current cursor position (not always!)
        bool SelectedAllMouseLock; /// after a double-click to select all, we ignore further mouse drags to update selection
        bool Edited; /// edited this frame
        bool WantReloadUserBuf; /// force a reload of user buf so it may be modified externally. may be automatic in future version.
        int ReloadSelectionStart;
        int ReloadSelectionEnd;
    }

    struct ImGuiLocEntry {
        ImGuiLocKey Key;
        const(char)* Text;
    }

    struct ImGuiPtrOrIndex {
        void* Ptr; /// Either field can be set, not both. e.g. Dock node tab bars are loose while BeginTabBar() ones are in a pool.
        int Index; /// Usually index in a main pool.
    }

    struct ImGuiDataTypeStorage {
        ImU8[8] Data; /// Opaque storage to fit any data up to ImGuiDataType_COUNT
    }

    /// Internal temporary state for deactivating InputText() instances.
    struct ImGuiInputTextDeactivatedState {
        ImGuiID ID; /// widget id owning the text state (which just got deactivated)
        ImVector!(char) TextA; /// text buffer
    }

    /// Coordinates of a rectangle within a texture.
    /// When a texture is in ImTextureStatus_WantUpdates state, we provide a list of individual rectangles to copy to the graphics system.
    /// You may use ImTextureData::Updates[] for the list, or ImTextureData::UpdateBox for a single bounding box.
    struct ImTextureRect {
        ushort x; /// Upper-left coordinates of rectangle to update
        ushort y; /// Upper-left coordinates of rectangle to update
        ushort w; /// Size of rectangle to update (in pixels)
        ushort h; /// Size of rectangle to update (in pixels)
    }

    /// Typically, 1 command = 1 GPU draw call (unless command is a callback)
    /// - VtxOffset: When 'io.BackendFlags & ImGuiBackendFlags_RendererHasVtxOffset' is enabled,
    ///   this fields allow us to render meshes larger than 64K vertices while keeping 16-bit indices.
    ///   Backends made for <1.71. will typically ignore the VtxOffset fields.
    /// - The ClipRect/TexRef/VtxOffset fields must be contiguous as we memcmp() them together (this is asserted for).
    struct ImDrawCmd {
        ImVec4 ClipRect; /// 4*4  /// Clipping rectangle (x1, y1, x2, y2). Subtract ImDrawData->DisplayPos to get clipping rectangle in "viewport" coordinates
        ImTextureRef TexRef; /// 16   /// Reference to a font/texture atlas (where backend called ImTextureData::SetTexID()) or to a user-provided texture ID (via e.g. ImGui::Image() calls). Both will lead to a ImTextureID value.
        uint VtxOffset; /// 4    /// Start offset in vertex buffer. ImGuiBackendFlags_RendererHasVtxOffset: always 0, otherwise may be >0 to support meshes larger than 64K vertices with 16-bit indices.
        uint IdxOffset; /// 4    /// Start offset in index buffer.
        uint ElemCount; /// 4    /// Number of indices (multiple of 3) to be rendered as triangles. Vertices are stored in the callee ImDrawList's vtx_buffer[] array, indices in idx_buffer[].
        ImDrawCallback UserCallback; /// 4-8  /// If != NULL, call the function instead of rendering the vertices. clip_rect and texture_id will be set normally.
        void* UserCallbackData; /// 4-8  /// Callback user data (when UserCallback != NULL). If called AddCallback() with size == 0, this is a copy of the AddCallback() argument. If called AddCallback() with size > 0, this is pointing to a buffer where data is stored.
        int UserCallbackDataSize; /// 4 /// Size of callback user data when using storage, otherwise 0.
        int UserCallbackDataOffset; /// 4 /// [Internal] Offset of callback user data when using storage, otherwise -1.
    }

    struct ImGuiContextHook {
        ImGuiID HookId; /// A unique ID assigned by AddContextHook()
        ImGuiContextHookType Type;
        ImGuiID Owner;
        ImGuiContextHookCallback Callback;
        void* UserData;
    }

    /// State for ID Stack tool queries
    struct ImGuiIDStackTool {
        int LastActiveFrame;
        int StackLevel; /// -1: query stack and resize Results, >= 0: individual stack level
        ImGuiID QueryId; /// ID to query details for
        ImVector!(ImGuiStackLevelInfo) Results;
        bool CopyToClipboardOnCtrlC;
        float CopyToClipboardLastTime;
        ImGuiTextBuffer ResultPathBuf;
    }

    /// Helper: ImGuiTextIndex
    /// Maintain a line index for a text buffer. This is a strong candidate to be moved into the public API.
    struct ImGuiTextIndex {
        ImVector!(int) LineOffsets;
        int EndOffset; /// Because we don't own text buffer we need to maintain EndOffset (may bake in LineOffsets?)
    }

    struct ImFontStackData {
        ImFont* Font;
        float FontSizeBeforeScaling; /// ~~ style.FontSizeBase
        float FontSizeAfterScaling; /// ~~ g.FontSize
    }

    struct ImGuiBoxSelectState {
         
            /// Active box-selection data (persistent, 1 active at a time)
        ImGuiID ID;
        bool IsActive;
        bool IsStarting;
        bool IsStartedFromVoid; /// Starting click was not from an item.
        bool IsStartedSetNavIdOnce;
        bool RequestClear;
        ImGuiKeyChord KeyMods; /// Latched key-mods for box-select logic.
        ImVec2 StartPosRel; /// Start position in window-contents relative space (to support scrolling)
        ImVec2 EndPosRel; /// End position in window-contents relative space
        ImVec2 ScrollAccum; /// Scrolling accumulator (to behave at high-frame spaces)
        ImGuiWindow* Window;
             /// Temporary/Transient data
        bool UnclipMode; /// (Temp/Transient, here in hot area). Set/cleared by the BeginMultiSelect()/EndMultiSelect() owning active box-select.
        ImRect UnclipRect; /// Rectangle where ItemAdd() clipping may be temporarily disabled. Need support by multi-select supporting widgets.
        ImRect BoxSelectRectPrev; /// Selection rectangle in absolute coordinates (derived every frame from BoxSelectStartPosRel and MousePos)
        ImRect BoxSelectRectCurr;
    }

    /// sizeof() 156~192
    struct ImGuiDockNode {
        ImGuiID ID;
        ImGuiDockNodeFlags SharedFlags; /// (Write) Flags shared by all nodes of a same dockspace hierarchy (inherited from the root node)
        ImGuiDockNodeFlags LocalFlags; /// (Write) Flags specific to this node
        ImGuiDockNodeFlags LocalFlagsInWindows; /// (Write) Flags specific to this node, applied from windows
        ImGuiDockNodeFlags MergedFlags; /// (Read)  Effective flags (== SharedFlags | LocalFlagsInNode | LocalFlagsInWindows)
        ImGuiDockNodeState State;
        ImGuiDockNode* ParentNode;
        ImGuiDockNode*[2] ChildNodes; /// [Split node only] Child nodes (left/right or top/bottom). Consider switching to an array.
        ImVector!(ImGuiWindow*) Windows; /// Note: unordered list! Iterate TabBar->Tabs for user-order.
        ImGuiTabBar* TabBar;
        ImVec2 Pos; /// Current position
        ImVec2 Size; /// Current size
        ImVec2 SizeRef; /// [Split node only] Last explicitly written-to size (overridden when using a splitter affecting the node), used to calculate Size.
        ImGuiAxis SplitAxis; /// [Split node only] Split axis (X or Y)
        ImGuiWindowClass WindowClass; /// [Root node only]
        ImU32 LastBgColor;
        ImGuiWindow* HostWindow;
        ImGuiWindow* VisibleWindow; /// Generally point to window which is ID is == SelectedTabID, but when CTRL+Tabbing this can be a different window.
        ImGuiDockNode* CentralNode; /// [Root node only] Pointer to central node.
        ImGuiDockNode* OnlyNodeWithWindows; /// [Root node only] Set when there is a single visible node within the hierarchy.
        int CountNodeWithWindows; /// [Root node only]
        int LastFrameAlive; /// Last frame number the node was updated or kept alive explicitly with DockSpace() + ImGuiDockNodeFlags_KeepAliveOnly
        int LastFrameActive; /// Last frame number the node was updated.
        int LastFrameFocused; /// Last frame number the node was focused.
        ImGuiID LastFocusedNodeId; /// [Root node only] Which of our child docking node (any ancestor in the hierarchy) was last focused.
        ImGuiID SelectedTabId; /// [Leaf node only] Which of our tab/window is selected.
        ImGuiID WantCloseTabId; /// [Leaf node only] Set when closing a specific tab/window.
        ImGuiID RefViewportId; /// Reference viewport ID from visible window when HostWindow == NULL.
        ImGuiDataAuthority AuthorityForPos;
        ImGuiDataAuthority AuthorityForSize;
        ImGuiDataAuthority AuthorityForViewport;
        bool IsVisible; /// Set to false when the node is hidden (usually disabled as it has no active window)
        bool IsFocused;
        bool IsBgDrawnThisFrame;
        bool HasCloseButton; /// Provide space for a close button (if any of the docked window has one). Note that button may be hidden on window without one.
        bool HasWindowMenuButton;
        bool HasCentralNodeChild;
        bool WantCloseAll; /// Set when closing all tabs at once.
        bool WantLockSizeOnce;
        bool WantMouseMove; /// After a node extraction we need to transition toward moving the newly created host window
        bool WantHiddenTabBarUpdate;
        bool WantHiddenTabBarToggle;
    }

    /// Helper: Key->Value storage
    /// Typically you don't have to worry about this since a storage is held within each Window.
    /// We use it to e.g. store collapse state for a tree (Int 0/1)
    /// This is optimized for efficient lookup (dichotomy into a contiguous buffer) and rare insertion (typically tied to user interactions aka max once a frame)
    /// You can use it as custom user storage for temporary values. Declare your own storage if, for example:
    /// - You want to manipulate the open/close state of a particular sub-tree in your interface (tree node uses Int 0/1 to store their state).
    /// - You want to store custom debug data easily without adding or editing structures in your code (probably not efficient, but convenient)
    /// Types are NOT stored, so it is up to you to make sure your Key don't collide with different types.
    struct ImGuiStorage {
         
            /// [Internal]
        ImVector!(ImGuiStoragePair) Data;
    }

    /// Helper to build glyph ranges from text/string data. Feed your application strings/characters to it then call BuildRanges().
    /// This is essentially a tightly packed of vector of 64k booleans = 8KB storage.
    struct ImFontGlyphRangesBuilder {
        ImVector!(ImU32) UsedChars; /// Store 1-bit per Unicode code point (0=unused, 1=used)
    }

    /// Helper: Parse and apply text filters. In format "aaaaa[,bbbb][,ccccc]"
    struct ImGuiTextFilter {
        char[256] InputBuf;
        ImVector!(ImGuiTextRange) Filters;
        int CountGrep;
    }

    /// Storage for a tab bar (sizeof() 160 bytes)
    struct ImGuiTabBar {
        ImGuiWindow* Window;
        ImVector!(ImGuiTabItem) Tabs;
        ImGuiTabBarFlags Flags;
        ImGuiID ID; /// Zero for tab-bars used by docking
        ImGuiID SelectedTabId; /// Selected tab/window
        ImGuiID NextSelectedTabId; /// Next selected tab/window. Will also trigger a scrolling animation
        ImGuiID VisibleTabId; /// Can occasionally be != SelectedTabId (e.g. when previewing contents for CTRL+TAB preview)
        int CurrFrameVisible;
        int PrevFrameVisible;
        ImRect BarRect;
        float CurrTabsContentsHeight;
        float PrevTabsContentsHeight; /// Record the height of contents submitted below the tab bar
        float WidthAllTabs; /// Actual width of all tabs (locked during layout)
        float WidthAllTabsIdeal; /// Ideal width if all tabs were visible and not clipped
        float ScrollingAnim;
        float ScrollingTarget;
        float ScrollingTargetDistToVisibility;
        float ScrollingSpeed;
        float ScrollingRectMinX;
        float ScrollingRectMaxX;
        float SeparatorMinX;
        float SeparatorMaxX;
        ImGuiID ReorderRequestTabId;
        ImS16 ReorderRequestOffset;
        ImS8 BeginCount;
        bool WantLayout;
        bool VisibleTabWasSubmitted;
        bool TabsAddedNew; /// Set to true when a new tab item or button has been added to the tab bar during last frame
        ImS16 TabsActiveCount; /// Number of tabs submitted this frame.
        ImS16 LastTabItemIdx; /// Index of last BeginTabItem() tab for use by EndTabItem()
        float ItemSpacingY;
        ImVec2 FramePadding; /// style.FramePadding locked at the time of BeginTabBar()
        ImVec2 BackupCursorPos;
        ImGuiTextBuffer TabsNames; /// For non-docking tab bar we re-append names in a contiguous buffer.
    }

    struct ImGuiInputEvent {
        ImGuiInputEventType Type;
        ImGuiInputSource Source;
        ImU32 EventId; /// Unique, sequential increasing integer to identify an event (if you need to correlate them to other data).
        union { ImGuiInputEventMousePos MousePos; ImGuiInputEventMouseWheel MouseWheel; ImGuiInputEventMouseButton MouseButton; ImGuiInputEventMouseViewport MouseViewport; ImGuiInputEventKey Key; ImGuiInputEventText Text; ImGuiInputEventAppFocused AppFocused;} ; /// if Type == ImGuiInputEventType_MousePos/// if Type == ImGuiInputEventType_MouseWheel/// if Type == ImGuiInputEventType_MouseButton/// if Type == ImGuiInputEventType_MouseViewport/// if Type == ImGuiInputEventType_Key/// if Type == ImGuiInputEventType_Text/// if Type == ImGuiInputEventType_Focus
        bool AddedByTestEngine;
    }

    struct ImVec2 {
        float x;
        float y;
    }

    /// Data used by IsItemDeactivated()/IsItemDeactivatedAfterEdit() functions
    struct ImGuiDeactivatedItemData {
        ImGuiID ID;
        int ElapseFrame;
        bool HasBeenEditedBefore;
        bool IsAlive;
    }

    struct ImDrawVert {
        ImVec2 pos;
        ImVec2 uv;
        ImU32 col;
    }

    /// Data available to potential texture post-processing functions
    struct ImFontAtlasPostProcessData {
        ImFontAtlas* FontAtlas;
        ImFont* Font;
        ImFontConfig* FontSrc;
        ImFontBaked* FontBaked;
        ImFontGlyph* Glyph;
             /// Pixel data
        char* Pixels;
        ImTextureFormat Format;
        int Pitch;
        int Width;
        int Height;
    }

    /// Stacked storage data for BeginGroup()/EndGroup()
    struct ImGuiGroupData {
        ImGuiID WindowID;
        ImVec2 BackupCursorPos;
        ImVec2 BackupCursorMaxPos;
        ImVec2 BackupCursorPosPrevLine;
        ImVec1 BackupIndent;
        ImVec1 BackupGroupOffset;
        ImVec2 BackupCurrLineSize;
        float BackupCurrLineTextBaseOffset;
        ImGuiID BackupActiveIdIsAlive;
        bool BackupDeactivatedIdIsAlive;
        bool BackupHoveredIdIsAlive;
        bool BackupIsSameLine;
        bool EmitItem;
    }

    /// Access via ImGui::GetPlatformIO()
    struct ImGuiPlatformIO {
             /// Optional: Access OS clipboard
            /// (default to use native Win32 clipboard on Windows, otherwise uses a private clipboard. Override to access OS clipboard on other architectures)
        const(char)* function(ImGuiContext* ctx) Platform_GetClipboardTextFn;
        void function(ImGuiContext* ctx,const(char)* text) Platform_SetClipboardTextFn;
        void* Platform_ClipboardUserData;
             /// Optional: Open link/folder/file in OS Shell
            /// (default to use ShellExecuteW() on Windows, system() on Linux/Mac)
        bool function(ImGuiContext* ctx,const(char)* path) Platform_OpenInShellFn;
        void* Platform_OpenInShellUserData;
             /// Optional: Notify OS Input Method Editor of the screen position of your cursor for text input position (e.g. when using Japanese/Chinese IME on Windows)
            /// (default to use native imm32 api on Windows)
        void function(ImGuiContext* ctx,ImGuiViewport* viewport,ImGuiPlatformImeData* data) Platform_SetImeDataFn;
        void* Platform_ImeUserData;
             /// Optional: Platform locale
            /// [Experimental] Configure decimal point e.g. '.' or ',' useful for some languages (e.g. German), generally pulled from *localeconv()->decimal_point
        ImWchar Platform_LocaleDecimalPoint; /// '.'
             /// Optional: Maximum texture size supported by renderer (used to adjust how we size textures). 0 if not known.
        int Renderer_TextureMaxWidth;
        int Renderer_TextureMaxHeight;
             /// Written by some backends during ImGui_ImplXXXX_RenderDrawData() call to point backend_specific ImGui_ImplXXXX_RenderState* structure.
        void* Renderer_RenderState;
             /// Platform Backend functions (e.g. Win32, GLFW, SDL) ------------------- Called by -----
        void function(ImGuiViewport* vp) Platform_CreateWindow; /// . . U . .  /// Create a new platform window for the given viewport
        void function(ImGuiViewport* vp) Platform_DestroyWindow; /// N . U . D  //
        void function(ImGuiViewport* vp) Platform_ShowWindow; /// . . U . .  /// Newly created windows are initially hidden so SetWindowPos/Size/Title can be called on them before showing the window
        void function(ImGuiViewport* vp,ImVec2 pos) Platform_SetWindowPos; /// . . U . .  /// Set platform window position (given the upper-left corner of client area)
        ImVec2 function(ImGuiViewport* vp) Platform_GetWindowPos; /// N . . . .  //
        void function(ImGuiViewport* vp,ImVec2 size) Platform_SetWindowSize; /// . . U . .  /// Set platform window client area size (ignoring OS decorations such as OS title bar etc.)
        ImVec2 function(ImGuiViewport* vp) Platform_GetWindowSize; /// N . . . .  /// Get platform window client area size
        ImVec2 function(ImGuiViewport* vp) Platform_GetWindowFramebufferScale; /// N . . . .  /// Return viewport density. Always 1,1 on Windows, often 2,2 on Retina display on macOS/iOS. MUST BE INTEGER VALUES.
        void function(ImGuiViewport* vp) Platform_SetWindowFocus; /// N . . . .  /// Move window to front and set input focus
        bool function(ImGuiViewport* vp) Platform_GetWindowFocus; /// . . U . .  //
        bool function(ImGuiViewport* vp) Platform_GetWindowMinimized; /// N . . . .  /// Get platform window minimized state. When minimized, we generally won't attempt to get/set size and contents will be culled more easily
        void function(ImGuiViewport* vp,const(char)* str) Platform_SetWindowTitle; /// . . U . .  /// Set platform window title (given an UTF-8 string)
        void function(ImGuiViewport* vp,float alpha) Platform_SetWindowAlpha; /// . . U . .  /// (Optional) Setup global transparency (not per-pixel transparency)
        void function(ImGuiViewport* vp) Platform_UpdateWindow; /// . . U . .  /// (Optional) Called by UpdatePlatformWindows(). Optional hook to allow the platform backend from doing general book-keeping every frame.
        void function(ImGuiViewport* vp,void* render_arg) Platform_RenderWindow; /// . . . R .  /// (Optional) Main rendering (platform side! This is often unused, or just setting a "current" context for OpenGL bindings). 'render_arg' is the value passed to RenderPlatformWindowsDefault().
        void function(ImGuiViewport* vp,void* render_arg) Platform_SwapBuffers; /// . . . R .  /// (Optional) Call Present/SwapBuffers (platform side! This is often unused!). 'render_arg' is the value passed to RenderPlatformWindowsDefault().
        float function(ImGuiViewport* vp) Platform_GetWindowDpiScale; /// N . . . .  /// (Optional) [BETA] FIXME-DPI: DPI handling: Return DPI scale for this viewport. 1.0f = 96 DPI.
        void function(ImGuiViewport* vp) Platform_OnChangedViewport; /// . F . . .  /// (Optional) [BETA] FIXME-DPI: DPI handling: Called during Begin() every time the viewport we are outputting into changes, so backend has a chance to swap fonts to adjust style.
        ImVec4 function(ImGuiViewport* vp) Platform_GetWindowWorkAreaInsets; /// N . . . .  /// (Optional) [BETA] Get initial work area inset for the viewport (won't be covered by main menu bar, dockspace over viewport etc.). Default to (0,0),(0,0). 'safeAreaInsets' in iOS land, 'DisplayCutout' in Android land.
        int function(ImGuiViewport* vp,ImU64 vk_inst,const void* vk_allocators,ImU64* out_vk_surface) Platform_CreateVkSurface; /// (Optional) For a Vulkan Renderer to call into Platform code (since the surface creation needs to tie them both).
             /// Renderer Backend functions (e.g. DirectX, OpenGL, Vulkan) ------------ Called by -----
        void function(ImGuiViewport* vp) Renderer_CreateWindow; /// . . U . .  /// Create swap chain, frame buffers etc. (called after Platform_CreateWindow)
        void function(ImGuiViewport* vp) Renderer_DestroyWindow; /// N . U . D  /// Destroy swap chain, frame buffers etc. (called before Platform_DestroyWindow)
        void function(ImGuiViewport* vp,ImVec2 size) Renderer_SetWindowSize; /// . . U . .  /// Resize swap chain, frame buffers etc. (called after Platform_SetWindowSize)
        void function(ImGuiViewport* vp,void* render_arg) Renderer_RenderWindow; /// . . . R .  /// (Optional) Clear framebuffer, setup render target, then render the viewport->DrawData. 'render_arg' is the value passed to RenderPlatformWindowsDefault().
        void function(ImGuiViewport* vp,void* render_arg) Renderer_SwapBuffers; /// . . . R .  /// (Optional) Call Present/SwapBuffers. 'render_arg' is the value passed to RenderPlatformWindowsDefault().
             /// (Optional) Monitor list
            /// - Updated by: app/backend. Update every frame to dynamically support changing monitor or DPI configuration.
            /// - Used by: dear imgui to query DPI info, clamp popups/tooltips within same monitor and not have them straddle monitors.
        ImVector!(ImGuiPlatformMonitor) Monitors;
             /// Textures list (the list is updated by calling ImGui::EndFrame or ImGui::Render)
            /// The ImGui_ImplXXXX_RenderDrawData() function of each backend generally access this via ImDrawData::Textures which points to this. The array is available here mostly because backends will want to destroy textures on shutdown.
        ImVector!(ImTextureData*) Textures; /// List of textures used by Dear ImGui (most often 1) + contents of external texture list is automatically appended into this.
             /// Viewports list (the list is updated by calling ImGui::EndFrame or ImGui::Render)
            /// (in the future we will attempt to organize this feature to remove the need for a "main viewport")
        ImVector!(ImGuiViewport*) Viewports; /// Main viewports, followed by all secondary viewports.
    }

    /// Helper: ImColor() implicitly converts colors to either ImU32 (packed 4x1 byte) or ImVec4 (4x1 float)
    /// Prefer using IM_COL32() macros if you want a guaranteed compile-time ImU32 for usage with ImDrawList API.
    /// **Avoid storing ImColor! Store either u32 of ImVec4. This is not a full-featured color class. MAY OBSOLETE.
    /// **None of the ImGui API are using ImColor directly but you can use it as a convenience to pass colors in either ImU32 or ImVec4 formats. Explicitly cast to ImU32 or ImVec4 if needed.
    struct ImColor {
        ImVec4 Value;
    }

    struct ImGuiOldColumns {
        ImGuiID ID;
        ImGuiOldColumnFlags Flags;
        bool IsFirstFrame;
        bool IsBeingResized;
        int Current;
        int Count;
        float OffMinX; /// Offsets from HostWorkRect.Min.x
        float OffMaxX; /// Offsets from HostWorkRect.Min.x
        float LineMinY;
        float LineMaxY;
        float HostCursorPosY; /// Backup of CursorPos at the time of BeginColumns()
        float HostCursorMaxPosX; /// Backup of CursorMaxPos at the time of BeginColumns()
        ImRect HostInitialClipRect; /// Backup of ClipRect at the time of BeginColumns()
        ImRect HostBackupClipRect; /// Backup of ClipRect during PushColumnsBackground()/PopColumnsBackground()
        ImRect HostBackupParentWorkRect; //Backup of WorkRect at the time of BeginColumns()
        ImVector!(ImGuiOldColumnData) Columns;
        ImDrawListSplitter Splitter;
    }

    /// Specs and pixel storage for a texture used by Dear ImGui.
    /// This is only useful for (1) core library and (2) backends. End-user/applications do not need to care about this.
    /// Renderer Backends will create a GPU-side version of this.
    /// Why does we store two identifiers: TexID and BackendUserData?
    /// - ImTextureID    TexID           = lower-level identifier stored in ImDrawCmd. ImDrawCmd can refer to textures not created by the backend, and for which there's no ImTextureData.
    /// - void*          BackendUserData = higher-level opaque storage for backend own book-keeping. Some backends may have enough with TexID and not need both.
     /// In columns below: who reads/writes each fields? 'r'=read, 'w'=write, 'core'=main library, 'backend'=renderer backend
    struct ImTextureData {
         
            //------------------------------------------ core / backend ---------------------------------------
        int UniqueID; /// w    -   /// Sequential index to facilitate identifying a texture when debugging/printing. Unique per atlas.
        ImTextureStatus Status; /// rw   rw  /// ImTextureStatus_OK/_WantCreate/_WantUpdates/_WantDestroy. Always use SetStatus() to modify!
        void* BackendUserData; /// -    rw  /// Convenience storage for backend. Some backends may have enough with TexID.
        ImTextureID TexID; /// r    w   /// Backend-specific texture identifier. Always use SetTexID() to modify! The identifier will stored in ImDrawCmd::GetTexID() and passed to backend's RenderDrawData function.
        ImTextureFormat Format; /// w    r   /// ImTextureFormat_RGBA32 (default) or ImTextureFormat_Alpha8
        int Width; /// w    r   /// Texture width
        int Height; /// w    r   /// Texture height
        int BytesPerPixel; /// w    r   /// 4 or 1
        char* Pixels; /// w    r   /// Pointer to buffer holding 'Width*Height' pixels and 'Width*Height*BytesPerPixels' bytes.
        ImTextureRect UsedRect; /// w    r   /// Bounding box encompassing all past and queued Updates[].
        ImTextureRect UpdateRect; /// w    r   /// Bounding box encompassing all queued Updates[].
        ImVector!(ImTextureRect) Updates; /// w    r   /// Array of individual updates.
        int UnusedFrames; /// w    r   /// In order to facilitate handling Status==WantDestroy in some backend: this is a count successive frames where the texture was not used. Always >0 when Status==WantDestroy.
        ushort RefCount; /// w    r   /// Number of contexts using this texture. Used during backend shutdown.
        bool UseColors; /// w    r   /// Tell whether our texture data is known to use colors (rather than just white + alpha).
        bool WantDestroyNextFrame; /// rw   -   /// [Internal] Queued to set ImTextureStatus_WantDestroy next frame. May still be used in the current frame.
    }

    struct ImGuiStyle {
         
            /// ImGui::GetFontSize() == FontSizeBase * (FontScaleMain * FontScaleDpi * other_scaling_factors)
        float FontSizeBase; /// Current base font size before external scaling factors are applied. Use PushFont()/PushFontSize() to modify. Use ImGui::GetFontSize() to obtain scaled value.
        float FontScaleMain; /// Main scale factor. May be set by application once, or exposed to end-user.
        float FontScaleDpi; /// Additional scale factor from viewport/monitor contents scale. When io.ConfigDpiScaleFonts is enabled, this is automatically overwritten when changing monitor DPI.
        float Alpha; /// Global alpha applies to everything in Dear ImGui.
        float DisabledAlpha; /// Additional alpha multiplier applied by BeginDisabled(). Multiply over current value of Alpha.
        ImVec2 WindowPadding; /// Padding within a window.
        float WindowRounding; /// Radius of window corners rounding. Set to 0.0f to have rectangular windows. Large values tend to lead to variety of artifacts and are not recommended.
        float WindowBorderSize; /// Thickness of border around windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
        float WindowBorderHoverPadding; /// Hit-testing extent outside/inside resizing border. Also extend determination of hovered window. Generally meaningfully larger than WindowBorderSize to make it easy to reach borders.
        ImVec2 WindowMinSize; /// Minimum window size. This is a global setting. If you want to constrain individual windows, use SetNextWindowSizeConstraints().
        ImVec2 WindowTitleAlign; /// Alignment for title bar text. Defaults to (0.0f,0.5f) for left-aligned,vertically centered.
        ImGuiDir WindowMenuButtonPosition; /// Side of the collapsing/docking button in the title bar (None/Left/Right). Defaults to ImGuiDir_Left.
        float ChildRounding; /// Radius of child window corners rounding. Set to 0.0f to have rectangular windows.
        float ChildBorderSize; /// Thickness of border around child windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
        float PopupRounding; /// Radius of popup window corners rounding. (Note that tooltip windows use WindowRounding)
        float PopupBorderSize; /// Thickness of border around popup/tooltip windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
        ImVec2 FramePadding; /// Padding within a framed rectangle (used by most widgets).
        float FrameRounding; /// Radius of frame corners rounding. Set to 0.0f to have rectangular frame (used by most widgets).
        float FrameBorderSize; /// Thickness of border around frames. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
        ImVec2 ItemSpacing; /// Horizontal and vertical spacing between widgets/lines.
        ImVec2 ItemInnerSpacing; /// Horizontal and vertical spacing between within elements of a composed widget (e.g. a slider and its label).
        ImVec2 CellPadding; /// Padding within a table cell. Cellpadding.x is locked for entire table. CellPadding.y may be altered between different rows.
        ImVec2 TouchExtraPadding; /// Expand reactive bounding box for touch-based system where touch position is not accurate enough. Unfortunately we don't sort widgets so priority on overlap will always be given to the first widget. So don't grow this too much!
        float IndentSpacing; /// Horizontal indentation when e.g. entering a tree node. Generally == (FontSize + FramePadding.x*2).
        float ColumnsMinSpacing; /// Minimum horizontal spacing between two columns. Preferably > (FramePadding.x + 1).
        float ScrollbarSize; /// Width of the vertical scrollbar, Height of the horizontal scrollbar.
        float ScrollbarRounding; /// Radius of grab corners for scrollbar.
        float GrabMinSize; /// Minimum width/height of a grab box for slider/scrollbar.
        float GrabRounding; /// Radius of grabs corners rounding. Set to 0.0f to have rectangular slider grabs.
        float LogSliderDeadzone; /// The size in pixels of the dead-zone around zero on logarithmic sliders that cross zero.
        float ImageBorderSize; /// Thickness of border around Image() calls.
        float TabRounding; /// Radius of upper corners of a tab. Set to 0.0f to have rectangular tabs.
        float TabBorderSize; /// Thickness of border around tabs.
        float TabCloseButtonMinWidthSelected; /// -1: always visible. 0.0f: visible when hovered. >0.0f: visible when hovered if minimum width.
        float TabCloseButtonMinWidthUnselected; /// -1: always visible. 0.0f: visible when hovered. >0.0f: visible when hovered if minimum width. FLT_MAX: never show close button when unselected.
        float TabBarBorderSize; /// Thickness of tab-bar separator, which takes on the tab active color to denote focus.
        float TabBarOverlineSize; /// Thickness of tab-bar overline, which highlights the selected tab-bar.
        float TableAngledHeadersAngle; /// Angle of angled headers (supported values range from -50.0f degrees to +50.0f degrees).
        ImVec2 TableAngledHeadersTextAlign; /// Alignment of angled headers within the cell
        ImGuiTreeNodeFlags TreeLinesFlags; /// Default way to draw lines connecting TreeNode hierarchy. ImGuiTreeNodeFlags_DrawLinesNone or ImGuiTreeNodeFlags_DrawLinesFull or ImGuiTreeNodeFlags_DrawLinesToNodes.
        float TreeLinesSize; /// Thickness of outlines when using ImGuiTreeNodeFlags_DrawLines.
        float TreeLinesRounding; /// Radius of lines connecting child nodes to the vertical line.
        ImGuiDir ColorButtonPosition; /// Side of the color button in the ColorEdit4 widget (left/right). Defaults to ImGuiDir_Right.
        ImVec2 ButtonTextAlign; /// Alignment of button text when button is larger than text. Defaults to (0.5f, 0.5f) (centered).
        ImVec2 SelectableTextAlign; /// Alignment of selectable text. Defaults to (0.0f, 0.0f) (top-left aligned). It's generally important to keep this left-aligned if you want to lay multiple items on a same line.
        float SeparatorTextBorderSize; /// Thickness of border in SeparatorText()
        ImVec2 SeparatorTextAlign; /// Alignment of text within the separator. Defaults to (0.0f, 0.5f) (left aligned, center).
        ImVec2 SeparatorTextPadding; /// Horizontal offset of text from each edge of the separator + spacing on other axis. Generally small values. .y is recommended to be == FramePadding.y.
        ImVec2 DisplayWindowPadding; /// Apply to regular windows: amount which we enforce to keep visible when moving near edges of your screen.
        ImVec2 DisplaySafeAreaPadding; /// Apply to every windows, menus, popups, tooltips: amount where we avoid displaying contents. Adjust if you cannot see the edges of your screen (e.g. on a TV where scaling has not been configured).
        float DockingSeparatorSize; /// Thickness of resizing border between docked windows
        float MouseCursorScale; /// Scale software rendered mouse cursor (when io.MouseDrawCursor is enabled). We apply per-monitor DPI scaling over this scale. May be removed later.
        bool AntiAliasedLines; /// Enable anti-aliased lines/borders. Disable if you are really tight on CPU/GPU. Latched at the beginning of the frame (copied to ImDrawList).
        bool AntiAliasedLinesUseTex; /// Enable anti-aliased lines/borders using textures where possible. Require backend to render with bilinear filtering (NOT point/nearest filtering). Latched at the beginning of the frame (copied to ImDrawList).
        bool AntiAliasedFill; /// Enable anti-aliased edges around filled shapes (rounded rectangles, circles, etc.). Disable if you are really tight on CPU/GPU. Latched at the beginning of the frame (copied to ImDrawList).
        float CurveTessellationTol; /// Tessellation tolerance when using PathBezierCurveTo() without a specific number of segments. Decrease for highly tessellated curves (higher quality, more polygons), increase to reduce quality.
        float CircleTessellationMaxError; /// Maximum error (in pixels) allowed when using AddCircle()/AddCircleFilled() or drawing rounded corner rectangles with no explicit segment count specified. Decrease for higher quality but more geometry.
             /// Colors
        ImVec4[ImGuiCol.COUNT] Colors;
             /// Behaviors
            /// (It is possible to modify those fields mid-frame if specific behavior need it, unlike e.g. configuration fields in ImGuiIO)
        float HoverStationaryDelay; /// Delay for IsItemHovered(ImGuiHoveredFlags_Stationary). Time required to consider mouse stationary.
        float HoverDelayShort; /// Delay for IsItemHovered(ImGuiHoveredFlags_DelayShort). Usually used along with HoverStationaryDelay.
        float HoverDelayNormal; /// Delay for IsItemHovered(ImGuiHoveredFlags_DelayNormal). "
        ImGuiHoveredFlags HoverFlagsForTooltipMouse; /// Default flags when using IsItemHovered(ImGuiHoveredFlags_ForTooltip) or BeginItemTooltip()/SetItemTooltip() while using mouse.
        ImGuiHoveredFlags HoverFlagsForTooltipNav; /// Default flags when using IsItemHovered(ImGuiHoveredFlags_ForTooltip) or BeginItemTooltip()/SetItemTooltip() while using keyboard/gamepad.
             /// [Internal]
        float _MainScale; /// FIXME-WIP: Reference scale, as applied by ScaleAllSizes().
        float _NextFrameFontSizeBase; /// FIXME: Temporary hack until we finish remaining work.
    }

    /// Internal storage for incrementally packing and building a ImFontAtlas
    struct ImFontAtlasBuilder {
        stbrp_context_opaque PackContext; /// Actually 'stbrp_context' but we don't want to define this in the header file.
        ImVector!(stbrp_node_im) PackNodes;
        ImVector!(ImTextureRect) Rects;
        ImVector!(ImFontAtlasRectEntry) RectsIndex; /// ImFontAtlasRectId -> index into Rects[]
        ImVector!(char) TempBuffer; /// Misc scratch buffer
        int RectsIndexFreeListStart; /// First unused entry
        int RectsPackedCount; /// Number of packed rectangles.
        int RectsPackedSurface; /// Number of packed pixels. Used when compacting to heuristically find the ideal texture size.
        int RectsDiscardedCount;
        int RectsDiscardedSurface;
        int FrameCount; /// Current frame count
        ImVec2i MaxRectSize; /// Largest rectangle to pack (de-facto used as a "minimum texture size")
        ImVec2i MaxRectBounds; /// Bottom-right most used pixels
        bool LockDisableResize; /// Disable resizing texture
        bool PreloadedAllGlyphsRanges; /// Set when missing ImGuiBackendFlags_RendererHasTextures features forces atlas to preload everything.
             /// Cache of all ImFontBaked
        ImStableVector!(ImFontBaked, 32) BakedPool;
        ImGuiStorage BakedMap; /// BakedId --> ImFontBaked*
        int BakedDiscardedCount;
             /// Custom rectangle identifiers
        ImFontAtlasRectId PackIdMouseCursors; /// White pixel + mouse cursors. Also happen to be fallback in case of packing failure.
        ImFontAtlasRectId PackIdLinesTexData;
    }

    struct ImGuiDebugAllocEntry {
        int FrameCount;
        ImS16 AllocCount;
        ImS16 FreeCount;
    }

    struct ImGuiContext {
        bool Initialized;
        ImGuiIO IO;
        ImGuiPlatformIO PlatformIO;
        ImGuiStyle Style;
        ImGuiConfigFlags ConfigFlagsCurrFrame; /// = g.IO.ConfigFlags at the time of NewFrame()
        ImGuiConfigFlags ConfigFlagsLastFrame;
        ImVector!(ImFontAtlas*) FontAtlases; /// List of font atlases used by the context (generally only contains g.IO.Fonts aka the main font atlas)
        ImFont* Font; /// Currently bound font. (== FontStack.back().Font)
        ImFontBaked* FontBaked; /// Currently bound font at currently bound size. (== Font->GetFontBaked(FontSize))
        float FontSize; /// Currently bound font size == line height (== FontSizeBase + externals scales applied in the UpdateCurrentFontSize() function).
        float FontSizeBase; /// Font size before scaling == style.FontSizeBase == value passed to PushFont() / PushFontSize() when specified.
        float FontBakedScale; /// == FontBaked->Size / FontSize. Scale factor over baked size. Rarely used nowadays, very often == 1.0f.
        float FontRasterizerDensity; /// Current font density. Used by all calls to GetFontBaked().
        float CurrentDpiScale; /// Current window/viewport DpiScale == CurrentViewport->DpiScale
        ImDrawListSharedData DrawListSharedData;
        double Time;
        int FrameCount;
        int FrameCountEnded;
        int FrameCountPlatformEnded;
        int FrameCountRendered;
        ImGuiID WithinEndChildID; /// Set within EndChild()
        bool WithinFrameScope; /// Set by NewFrame(), cleared by EndFrame()
        bool WithinFrameScopeWithImplicitWindow; /// Set by NewFrame(), cleared by EndFrame() when the implicit debug window has been pushed
        bool GcCompactAll; /// Request full GC
        bool TestEngineHookItems; /// Will call test engine hooks: ImGuiTestEngineHook_ItemAdd(), ImGuiTestEngineHook_ItemInfo(), ImGuiTestEngineHook_Log()
        void* TestEngine; /// Test engine user data
        char[16] ContextName; /// Storage for a context name (to facilitate debugging multi-context setups)
             /// Inputs
        ImVector!(ImGuiInputEvent) InputEventsQueue; /// Input events which will be trickled/written into IO structure.
        ImVector!(ImGuiInputEvent) InputEventsTrail; /// Past input events processed in NewFrame(). This is to allow domain-specific application to access e.g mouse/pen trail.
        ImGuiMouseSource InputEventsNextMouseSource;
        ImU32 InputEventsNextEventId;
             /// Windows state
        ImVector!(ImGuiWindow*) Windows; /// Windows, sorted in display order, back to front
        ImVector!(ImGuiWindow*) WindowsFocusOrder; /// Root windows, sorted in focus order, back to front.
        ImVector!(ImGuiWindow*) WindowsTempSortBuffer; /// Temporary buffer used in EndFrame() to reorder windows so parents are kept before their child
        ImVector!(ImGuiWindowStackData) CurrentWindowStack;
        ImGuiStorage WindowsById; /// Map window's ImGuiID to ImGuiWindow*
        int WindowsActiveCount; /// Number of unique windows submitted by frame
        float WindowsBorderHoverPadding; /// Padding around resizable windows for which hovering on counts as hovering the window == ImMax(style.TouchExtraPadding, style.WindowBorderHoverPadding). This isn't so multi-dpi friendly.
        ImGuiID DebugBreakInWindow; /// Set to break in Begin() call.
        ImGuiWindow* CurrentWindow; /// Window being drawn into
        ImGuiWindow* HoveredWindow; /// Window the mouse is hovering. Will typically catch mouse inputs.
        ImGuiWindow* HoveredWindowUnderMovingWindow; /// Hovered window ignoring MovingWindow. Only set if MovingWindow is set.
        ImGuiWindow* HoveredWindowBeforeClear; /// Window the mouse is hovering. Filled even with _NoMouse. This is currently useful for multi-context compositors.
        ImGuiWindow* MovingWindow; /// Track the window we clicked on (in order to preserve focus). The actual window that is moved is generally MovingWindow->RootWindowDockTree.
        ImGuiWindow* WheelingWindow; /// Track the window we started mouse-wheeling on. Until a timer elapse or mouse has moved, generally keep scrolling the same window even if during the course of scrolling the mouse ends up hovering a child window.
        ImVec2 WheelingWindowRefMousePos;
        int WheelingWindowStartFrame; /// This may be set one frame before WheelingWindow is != NULL
        int WheelingWindowScrolledFrame;
        float WheelingWindowReleaseTimer;
        ImVec2 WheelingWindowWheelRemainder;
        ImVec2 WheelingAxisAvg;
             /// Item/widgets state and tracking information
        ImGuiID DebugDrawIdConflicts; /// Set when we detect multiple items with the same identifier
        ImGuiID DebugHookIdInfo; /// Will call core hooks: DebugHookIdInfo() from GetID functions, used by ID Stack Tool [next HoveredId/ActiveId to not pull in an extra cache-line]
        ImGuiID HoveredId; /// Hovered widget, filled during the frame
        ImGuiID HoveredIdPreviousFrame;
        int HoveredIdPreviousFrameItemCount; /// Count numbers of items using the same ID as last frame's hovered id
        float HoveredIdTimer; /// Measure contiguous hovering time
        float HoveredIdNotActiveTimer; /// Measure contiguous hovering time where the item has not been active
        bool HoveredIdAllowOverlap;
        bool HoveredIdIsDisabled; /// At least one widget passed the rect test, but has been discarded by disabled flag or popup inhibit. May be true even if HoveredId == 0.
        bool ItemUnclipByLog; /// Disable ItemAdd() clipping, essentially a memory-locality friendly copy of LogEnabled
        ImGuiID ActiveId; /// Active widget
        ImGuiID ActiveIdIsAlive; /// Active widget has been seen this frame (we can't use a bool as the ActiveId may change within the frame)
        float ActiveIdTimer;
        bool ActiveIdIsJustActivated; /// Set at the time of activation for one frame
        bool ActiveIdAllowOverlap; /// Active widget allows another widget to steal active id (generally for overlapping widgets, but not always)
        bool ActiveIdNoClearOnFocusLoss; /// Disable losing active id if the active id window gets unfocused.
        bool ActiveIdHasBeenPressedBefore; /// Track whether the active id led to a press (this is to allow changing between PressOnClick and PressOnRelease without pressing twice). Used by range_select branch.
        bool ActiveIdHasBeenEditedBefore; /// Was the value associated to the widget Edited over the course of the Active state.
        bool ActiveIdHasBeenEditedThisFrame;
        bool ActiveIdFromShortcut;
        int ActiveIdMouseButton;
        ImVec2 ActiveIdClickOffset; /// Clicked offset from upper-left corner, if applicable (currently only set by ButtonBehavior)
        ImGuiWindow* ActiveIdWindow;
        ImGuiInputSource ActiveIdSource; /// Activating source: ImGuiInputSource_Mouse OR ImGuiInputSource_Keyboard OR ImGuiInputSource_Gamepad
        ImGuiID ActiveIdPreviousFrame;
        ImGuiDeactivatedItemData DeactivatedItemData;
        ImGuiDataTypeStorage ActiveIdValueOnActivation; /// Backup of initial value at the time of activation. ONLY SET BY SPECIFIC WIDGETS: DragXXX and SliderXXX.
        ImGuiID LastActiveId; /// Store the last non-zero ActiveId, useful for animation.
        float LastActiveIdTimer; /// Store the last non-zero ActiveId timer since the beginning of activation, useful for animation.
             /// Key/Input Ownership + Shortcut Routing system
            /// - The idea is that instead of "eating" a given key, we can link to an owner.
            /// - Input query can then read input by specifying ImGuiKeyOwner_Any (== 0), ImGuiKeyOwner_NoOwner (== -1) or a custom ID.
            /// - Routing is requested ahead of time for a given chord (Key + Mods) and granted in NewFrame().
        double LastKeyModsChangeTime; /// Record the last time key mods changed (affect repeat delay when using shortcut logic)
        double LastKeyModsChangeFromNoneTime; /// Record the last time key mods changed away from being 0 (affect repeat delay when using shortcut logic)
        double LastKeyboardKeyPressTime; /// Record the last time a keyboard key (ignore mouse/gamepad ones) was pressed.
        ImBitArrayForNamedKeys KeysMayBeCharInput; /// Lookup to tell if a key can emit char input, see IsKeyChordPotentiallyCharInput(). sizeof() = 20 bytes
        ImGuiKeyOwnerData[ImGuiKey.NamedKey_COUNT] KeysOwnerData;
        ImGuiKeyRoutingTable KeysRoutingTable;
        ImU32 ActiveIdUsingNavDirMask; /// Active widget will want to read those nav move requests (e.g. can activate a button and move away from it)
        bool ActiveIdUsingAllKeyboardKeys; /// Active widget will want to read all keyboard keys inputs. (this is a shortcut for not taking ownership of 100+ keys, frequently used by drag operations)
        ImGuiKeyChord DebugBreakInShortcutRouting; /// Set to break in SetShortcutRouting()/Shortcut() calls.
             /// Next window/item data
        ImGuiID CurrentFocusScopeId; /// Value for currently appending items == g.FocusScopeStack.back(). Not to be mistaken with g.NavFocusScopeId.
        ImGuiItemFlags CurrentItemFlags; /// Value for currently appending items == g.ItemFlagsStack.back()
        ImGuiID DebugLocateId; /// Storage for DebugLocateItemOnHover() feature: this is read by ItemAdd() so we keep it in a hot/cached location
        ImGuiNextItemData NextItemData; /// Storage for SetNextItem** functions
        ImGuiLastItemData LastItemData; /// Storage for last submitted item (setup by ItemAdd)
        ImGuiNextWindowData NextWindowData; /// Storage for SetNextWindow** functions
        bool DebugShowGroupRects;
             /// Shared stacks
        ImGuiCol DebugFlashStyleColorIdx; /// (Keep close to ColorStack to share cache line)
        ImVector!(ImGuiColorMod) ColorStack; /// Stack for PushStyleColor()/PopStyleColor() - inherited by Begin()
        ImVector!(ImGuiStyleMod) StyleVarStack; /// Stack for PushStyleVar()/PopStyleVar() - inherited by Begin()
        ImVector!(ImFontStackData) FontStack; /// Stack for PushFont()/PopFont() - inherited by Begin()
        ImVector!(ImGuiFocusScopeData) FocusScopeStack; /// Stack for PushFocusScope()/PopFocusScope() - inherited by BeginChild(), pushed into by Begin()
        ImVector!(ImGuiItemFlags) ItemFlagsStack; /// Stack for PushItemFlag()/PopItemFlag() - inherited by Begin()
        ImVector!(ImGuiGroupData) GroupStack; /// Stack for BeginGroup()/EndGroup() - not inherited by Begin()
        ImVector!(ImGuiPopupData) OpenPopupStack; /// Which popups are open (persistent)
        ImVector!(ImGuiPopupData) BeginPopupStack; /// Which level of BeginPopup() we are in (reset every frame)
        ImVector!(ImGuiTreeNodeStackData) TreeNodeStack; /// Stack for TreeNode()
             /// Viewports
        ImVector!(ImGuiViewportP*) Viewports; /// Active viewports (always 1+, and generally 1 unless multi-viewports are enabled). Each viewports hold their copy of ImDrawData.
        ImGuiViewportP* CurrentViewport; /// We track changes of viewport (happening in Begin) so we can call Platform_OnChangedViewport()
        ImGuiViewportP* MouseViewport;
        ImGuiViewportP* MouseLastHoveredViewport; /// Last known viewport that was hovered by mouse (even if we are not hovering any viewport any more) + honoring the _NoInputs flag.
        ImGuiID PlatformLastFocusedViewportId;
        ImGuiPlatformMonitor FallbackMonitor; /// Virtual monitor used as fallback if backend doesn't provide monitor information.
        ImRect PlatformMonitorsFullWorkRect; /// Bounding box of all platform monitors
        int ViewportCreatedCount; /// Unique sequential creation counter (mostly for testing/debugging)
        int PlatformWindowsCreatedCount; /// Unique sequential creation counter (mostly for testing/debugging)
        int ViewportFocusedStampCount; /// Every time the front-most window changes, we stamp its viewport with an incrementing counter
             /// Keyboard/Gamepad Navigation
        bool NavCursorVisible; /// Nav focus cursor/rectangle is visible? We hide it after a mouse click. We show it after a nav move.
        bool NavHighlightItemUnderNav; /// Disable mouse hovering highlight. Highlight navigation focused item instead of mouse hovered item.
         
            //bool                  NavDisableHighlight;                /// Old name for !g.NavCursorVisible before 1.91.4 (2024/10/18). OPPOSITE VALUE (g.NavDisableHighlight == !g.NavCursorVisible)
            //bool                  NavDisableMouseHover;               /// Old name for g.NavHighlightItemUnderNav before 1.91.1 (2024/10/18) this was called When user starts using keyboard/gamepad, we hide mouse hovering highlight until mouse is touched again.
        bool NavMousePosDirty; /// When set we will update mouse position if io.ConfigNavMoveSetMousePos is set (not enabled by default)
        bool NavIdIsAlive; /// Nav widget has been seen this frame ~~ NavRectRel is valid
        ImGuiID NavId; /// Focused item for navigation
        ImGuiWindow* NavWindow; /// Focused window for navigation. Could be called 'FocusedWindow'
        ImGuiID NavFocusScopeId; /// Focused focus scope (e.g. selection code often wants to "clear other items" when landing on an item of the same scope)
        ImGuiNavLayer NavLayer; /// Focused layer (main scrolling layer, or menu/title bar layer)
        ImGuiID NavActivateId; /// ~~ (g.ActiveId == 0) && (IsKeyPressed(ImGuiKey_Space) || IsKeyDown(ImGuiKey_Enter) || IsKeyPressed(ImGuiKey_NavGamepadActivate)) ? NavId : 0, also set when calling ActivateItem()
        ImGuiID NavActivateDownId; /// ~~ IsKeyDown(ImGuiKey_Space) || IsKeyDown(ImGuiKey_Enter) || IsKeyDown(ImGuiKey_NavGamepadActivate) ? NavId : 0
        ImGuiID NavActivatePressedId; /// ~~ IsKeyPressed(ImGuiKey_Space) || IsKeyPressed(ImGuiKey_Enter) || IsKeyPressed(ImGuiKey_NavGamepadActivate) ? NavId : 0 (no repeat)
        ImGuiActivateFlags NavActivateFlags;
        ImVector!(ImGuiFocusScopeData) NavFocusRoute; /// Reversed copy focus scope stack for NavId (should contains NavFocusScopeId). This essentially follow the window->ParentWindowForFocusRoute chain.
        ImGuiID NavHighlightActivatedId;
        float NavHighlightActivatedTimer;
        ImGuiID NavNextActivateId; /// Set by ActivateItem(), queued until next frame.
        ImGuiActivateFlags NavNextActivateFlags;
        ImGuiInputSource NavInputSource; /// Keyboard or Gamepad mode? THIS CAN ONLY BE ImGuiInputSource_Keyboard or ImGuiInputSource_Mouse
        ImGuiSelectionUserData NavLastValidSelectionUserData; /// Last valid data passed to SetNextItemSelectionUser(), or -1. For current window. Not reset when focusing an item that doesn't have selection data.
        ImS8 NavCursorHideFrames;
             /// Navigation: Init & Move Requests
        bool NavAnyRequest; /// ~~ NavMoveRequest || NavInitRequest this is to perform early out in ItemAdd()
        bool NavInitRequest; /// Init request for appearing window to select first item
        bool NavInitRequestFromMove;
        ImGuiNavItemData NavInitResult; /// Init request result (first item of the window, or one for which SetItemDefaultFocus() was called)
        bool NavMoveSubmitted; /// Move request submitted, will process result on next NewFrame()
        bool NavMoveScoringItems; /// Move request submitted, still scoring incoming items
        bool NavMoveForwardToNextFrame;
        ImGuiNavMoveFlags NavMoveFlags;
        ImGuiScrollFlags NavMoveScrollFlags;
        ImGuiKeyChord NavMoveKeyMods;
        ImGuiDir NavMoveDir; /// Direction of the move request (left/right/up/down)
        ImGuiDir NavMoveDirForDebug;
        ImGuiDir NavMoveClipDir; /// FIXME-NAV: Describe the purpose of this better. Might want to rename?
        ImRect NavScoringRect; /// Rectangle used for scoring, in screen space. Based of window->NavRectRel[], modified for directional navigation scoring.
        ImRect NavScoringNoClipRect; /// Some nav operations (such as PageUp/PageDown) enforce a region which clipper will attempt to always keep submitted
        int NavScoringDebugCount; /// Metrics for debugging
        int NavTabbingDir; /// Generally -1 or +1, 0 when tabbing without a nav id
        int NavTabbingCounter; /// >0 when counting items for tabbing
        ImGuiNavItemData NavMoveResultLocal; /// Best move request candidate within NavWindow
        ImGuiNavItemData NavMoveResultLocalVisible; /// Best move request candidate within NavWindow that are mostly visible (when using ImGuiNavMoveFlags_AlsoScoreVisibleSet flag)
        ImGuiNavItemData NavMoveResultOther; /// Best move request candidate within NavWindow's flattened hierarchy (when using ImGuiWindowFlags_NavFlattened flag)
        ImGuiNavItemData NavTabbingResultFirst; /// First tabbing request candidate within NavWindow and flattened hierarchy
             /// Navigation: record of last move request
        ImGuiID NavJustMovedFromFocusScopeId; /// Just navigated from this focus scope id (result of a successfully MoveRequest).
        ImGuiID NavJustMovedToId; /// Just navigated to this id (result of a successfully MoveRequest).
        ImGuiID NavJustMovedToFocusScopeId; /// Just navigated to this focus scope id (result of a successfully MoveRequest).
        ImGuiKeyChord NavJustMovedToKeyMods;
        bool NavJustMovedToIsTabbing; /// Copy of ImGuiNavMoveFlags_IsTabbing. Maybe we should store whole flags.
        bool NavJustMovedToHasSelectionData; /// Copy of move result's ItemFlags & ImGuiItemFlags_HasSelectionUserData). Maybe we should just store ImGuiNavItemData.
             /// Navigation: Windowing (CTRL+TAB for list, or Menu button + keys or directional pads to move/resize)
        bool ConfigNavWindowingWithGamepad; /// = true. Enable CTRL+TAB by holding ImGuiKey_GamepadFaceLeft (== ImGuiKey_NavGamepadMenu). When false, the button may still be used to toggle Menu layer.
        ImGuiKeyChord ConfigNavWindowingKeyNext; /// = ImGuiMod_Ctrl | ImGuiKey_Tab (or ImGuiMod_Super | ImGuiKey_Tab on OS X). For reconfiguration (see #4828)
        ImGuiKeyChord ConfigNavWindowingKeyPrev; /// = ImGuiMod_Ctrl | ImGuiMod_Shift | ImGuiKey_Tab (or ImGuiMod_Super | ImGuiMod_Shift | ImGuiKey_Tab on OS X)
        ImGuiWindow* NavWindowingTarget; /// Target window when doing CTRL+Tab (or Pad Menu + FocusPrev/Next), this window is temporarily displayed top-most!
        ImGuiWindow* NavWindowingTargetAnim; /// Record of last valid NavWindowingTarget until DimBgRatio and NavWindowingHighlightAlpha becomes 0.0f, so the fade-out can stay on it.
        ImGuiWindow* NavWindowingListWindow; /// Internal window actually listing the CTRL+Tab contents
        float NavWindowingTimer;
        float NavWindowingHighlightAlpha;
        ImGuiInputSource NavWindowingInputSource;
        bool NavWindowingToggleLayer;
        ImGuiKey NavWindowingToggleKey;
        ImVec2 NavWindowingAccumDeltaPos;
        ImVec2 NavWindowingAccumDeltaSize;
             /// Render
        float DimBgRatio; /// 0.0..1.0 animation when fading in a dimming background (for modal window and CTRL+TAB list)
             /// Drag and Drop
        bool DragDropActive;
        bool DragDropWithinSource; /// Set when within a BeginDragDropXXX/EndDragDropXXX block for a drag source.
        bool DragDropWithinTarget; /// Set when within a BeginDragDropXXX/EndDragDropXXX block for a drag target.
        ImGuiDragDropFlags DragDropSourceFlags;
        int DragDropSourceFrameCount;
        int DragDropMouseButton;
        ImGuiPayload DragDropPayload;
        ImRect DragDropTargetRect; /// Store rectangle of current target candidate (we favor small targets when overlapping)
        ImRect DragDropTargetClipRect; /// Store ClipRect at the time of item's drawing
        ImGuiID DragDropTargetId;
        ImGuiDragDropFlags DragDropAcceptFlags;
        float DragDropAcceptIdCurrRectSurface; /// Target item surface (we resolve overlapping targets by prioritizing the smaller surface)
        ImGuiID DragDropAcceptIdCurr; /// Target item id (set at the time of accepting the payload)
        ImGuiID DragDropAcceptIdPrev; /// Target item id from previous frame (we need to store this to allow for overlapping drag and drop targets)
        int DragDropAcceptFrameCount; /// Last time a target expressed a desire to accept the source
        ImGuiID DragDropHoldJustPressedId; /// Set when holding a payload just made ButtonBehavior() return a press.
        ImVector!(char) DragDropPayloadBufHeap; /// We don't expose the ImVector<> directly, ImGuiPayload only holds pointer+size
        char[16] DragDropPayloadBufLocal; /// Local buffer for small payloads
             /// Clipper
        int ClipperTempDataStacked;
        ImVector!(ImGuiListClipperData) ClipperTempData;
             /// Tables
        ImGuiTable* CurrentTable;
        ImGuiID DebugBreakInTable; /// Set to break in BeginTable() call.
        int TablesTempDataStacked; /// Temporary table data size (because we leave previous instances undestructed, we generally don't use TablesTempData.Size)
        ImVector!(ImGuiTableTempData) TablesTempData; /// Temporary table data (buffers reused/shared across instances, support nesting)
        ImPool_ImGuiTable Tables; /// Persistent table data
        ImVector!(float) TablesLastTimeActive; /// Last used timestamp of each tables (SOA, for efficient GC)
        ImVector!(ImDrawChannel) DrawChannelsTempMergeBuffer;
             /// Tab bars
        ImGuiTabBar* CurrentTabBar;
        ImPool_ImGuiTabBar TabBars;
        ImVector!(ImGuiPtrOrIndex) CurrentTabBarStack;
        ImVector!(ImGuiShrinkWidthItem) ShrinkWidthBuffer;
             /// Multi-Select state
        ImGuiBoxSelectState BoxSelectState;
        ImGuiMultiSelectTempData* CurrentMultiSelect;
        int MultiSelectTempDataStacked; /// Temporary multi-select data size (because we leave previous instances undestructed, we generally don't use MultiSelectTempData.Size)
        ImVector!(ImGuiMultiSelectTempData) MultiSelectTempData;
        ImPool_ImGuiMultiSelectState MultiSelectStorage;
             /// Hover Delay system
        ImGuiID HoverItemDelayId;
        ImGuiID HoverItemDelayIdPreviousFrame;
        float HoverItemDelayTimer; /// Currently used by IsItemHovered()
        float HoverItemDelayClearTimer; /// Currently used by IsItemHovered(): grace time before g.TooltipHoverTimer gets cleared.
        ImGuiID HoverItemUnlockedStationaryId; /// Mouse has once been stationary on this item. Only reset after departing the item.
        ImGuiID HoverWindowUnlockedStationaryId; /// Mouse has once been stationary on this window. Only reset after departing the window.
             /// Mouse state
        ImGuiMouseCursor MouseCursor;
        float MouseStationaryTimer; /// Time the mouse has been stationary (with some loose heuristic)
        ImVec2 MouseLastValidPos;
             /// Widget state
        ImGuiInputTextState InputTextState;
        ImGuiInputTextDeactivatedState InputTextDeactivatedState;
        ImFontBaked InputTextPasswordFontBackupBaked;
        ImFontFlags InputTextPasswordFontBackupFlags;
        ImGuiID TempInputId; /// Temporary text input when CTRL+clicking on a slider, etc.
        ImGuiDataTypeStorage DataTypeZeroValue; /// 0 for all data types
        int BeginMenuDepth;
        int BeginComboDepth;
        ImGuiColorEditFlags ColorEditOptions; /// Store user options for color edit widgets
        ImGuiID ColorEditCurrentID; /// Set temporarily while inside of the parent-most ColorEdit4/ColorPicker4 (because they call each others).
        ImGuiID ColorEditSavedID; /// ID we are saving/restoring HS for
        float ColorEditSavedHue; /// Backup of last Hue associated to LastColor, so we can restore Hue in lossy RGB<>HSV round trips
        float ColorEditSavedSat; /// Backup of last Saturation associated to LastColor, so we can restore Saturation in lossy RGB<>HSV round trips
        ImU32 ColorEditSavedColor; /// RGB value with alpha set to 0.
        ImVec4 ColorPickerRef; /// Initial/reference color at the time of opening the color picker.
        ImGuiComboPreviewData ComboPreviewData;
        ImRect WindowResizeBorderExpectedRect; /// Expected border rect, switch to relative edit if moving
        bool WindowResizeRelativeMode;
        short ScrollbarSeekMode; /// 0: scroll to clicked location, -1/+1: prev/next page.
        float ScrollbarClickDeltaToGrabCenter; /// When scrolling to mouse location: distance between mouse and center of grab box, normalized in parent space.
        float SliderGrabClickOffset;
        float SliderCurrentAccum; /// Accumulated slider delta when using navigation controls.
        bool SliderCurrentAccumDirty; /// Has the accumulated slider delta changed since last time we tried to apply it?
        bool DragCurrentAccumDirty;
        float DragCurrentAccum; /// Accumulator for dragging modification. Always high-precision, not rounded by end-user precision settings
        float DragSpeedDefaultRatio; /// If speed == 0.0f, uses (max-min) * DragSpeedDefaultRatio
        float DisabledAlphaBackup; /// Backup for style.Alpha for BeginDisabled()
        short DisabledStackSize;
        short TooltipOverrideCount;
        ImGuiWindow* TooltipPreviousWindow; /// Window of last tooltip submitted during the frame
        ImVector!(char) ClipboardHandlerData; /// If no custom clipboard handler is defined
        ImVector!(ImGuiID) MenusIdSubmittedThisFrame; /// A list of menu IDs that were rendered at least once
        ImGuiTypingSelectState TypingSelectState; /// State for GetTypingSelectRequest()
             /// Platform support
        ImGuiPlatformImeData PlatformImeData; /// Data updated by current frame. Will be applied at end of the frame. For some backends, this is required to have WantVisible=true in order to receive text message.
        ImGuiPlatformImeData PlatformImeDataPrev; /// Previous frame data. When changed we call the platform_io.Platform_SetImeDataFn() handler.
             /// Extensions
            /// FIXME: We could provide an API to register one slot in an array held in ImGuiContext?
        ImVector!(ImTextureData*) UserTextures; /// List of textures created/managed by user or third-party extension. Automatically appended into platform_io.Textures[].
        ImGuiDockContext DockContext;
        void function(ImGuiContext* ctx,ImGuiDockNode* node,ImGuiTabBar* tab_bar) DockNodeWindowMenuHandler;
             /// Settings
        bool SettingsLoaded;
        float SettingsDirtyTimer; /// Save .ini Settings to memory when time reaches zero
        ImGuiTextBuffer SettingsIniData; /// In memory .ini settings
        ImVector!(ImGuiSettingsHandler) SettingsHandlers; /// List of .ini settings handlers
        ImChunkStream_ImGuiWindowSettings SettingsWindows; /// ImGuiWindow .ini settings entries
        ImChunkStream_ImGuiTableSettings SettingsTables; /// ImGuiTable .ini settings entries
        ImVector!(ImGuiContextHook) Hooks; /// Hooks for extensions (e.g. test engine)
        ImGuiID HookIdNext; /// Next available HookId
             /// Localization
        const(char)*[ImGuiLocKey.COUNT] LocalizationTable;
             /// Capture/Logging
        bool LogEnabled; /// Currently capturing
        ImGuiLogFlags LogFlags; /// Capture flags/type
        ImGuiWindow* LogWindow;
        ImFileHandle LogFile; /// If != NULL log to stdout/ file
        ImGuiTextBuffer LogBuffer; /// Accumulation buffer when log to clipboard. This is pointer so our GImGui static constructor doesn't call heap allocators.
        const(char)* LogNextPrefix;
        const(char)* LogNextSuffix;
        float LogLinePosY;
        bool LogLineFirstItem;
        int LogDepthRef;
        int LogDepthToExpand;
        int LogDepthToExpandDefault; /// Default/stored value for LogDepthMaxExpand if not specified in the LogXXX function call.
             /// Error Handling
        ImGuiErrorCallback ErrorCallback; /// = NULL. May be exposed in public API eventually.
        void* ErrorCallbackUserData; /// = NULL
        ImVec2 ErrorTooltipLockedPos;
        bool ErrorFirst;
        int ErrorCountCurrentFrame; /// [Internal] Number of errors submitted this frame.
        ImGuiErrorRecoveryState StackSizesInNewFrame; /// [Internal]
        ImGuiErrorRecoveryState* StackSizesInBeginForCurrentWindow; /// [Internal]
             /// Debug Tools
            /// (some of the highly frequently used data are interleaved in other structures above: DebugBreakXXX fields, DebugHookIdInfo, DebugLocateId etc.)
        int DebugDrawIdConflictsCount; /// Locked count (preserved when holding CTRL)
        ImGuiDebugLogFlags DebugLogFlags;
        ImGuiTextBuffer DebugLogBuf;
        ImGuiTextIndex DebugLogIndex;
        int DebugLogSkippedErrors;
        ImGuiDebugLogFlags DebugLogAutoDisableFlags;
        ImU8 DebugLogAutoDisableFrames;
        ImU8 DebugLocateFrames; /// For DebugLocateItemOnHover(). This is used together with DebugLocateId which is in a hot/cached spot above.
        bool DebugBreakInLocateId; /// Debug break in ItemAdd() call for g.DebugLocateId.
        ImGuiKeyChord DebugBreakKeyChord; /// = ImGuiKey_Pause
        ImS8 DebugBeginReturnValueCullDepth; /// Cycle between 0..9 then wrap around.
        bool DebugItemPickerActive; /// Item picker is active (started with DebugStartItemPicker())
        ImU8 DebugItemPickerMouseButton;
        ImGuiID DebugItemPickerBreakId; /// Will call IM_DEBUG_BREAK() when encountering this ID
        float DebugFlashStyleColorTime;
        ImVec4 DebugFlashStyleColorBackup;
        ImGuiMetricsConfig DebugMetricsConfig;
        ImGuiIDStackTool DebugIDStackTool;
        ImGuiDebugAllocInfo DebugAllocInfo;
        ImGuiDockNode* DebugHoveredDockNode; /// Hovered dock node.
             /// Misc
        float[60] FramerateSecPerFrame; /// Calculate estimate of framerate for user over the last 60 frames..
        int FramerateSecPerFrameIdx;
        int FramerateSecPerFrameCount;
        float FramerateSecPerFrameAccum;
        int WantCaptureMouseNextFrame; /// Explicit capture override via SetNextFrameWantCaptureMouse()/SetNextFrameWantCaptureKeyboard(). Default to -1.
        int WantCaptureKeyboardNextFrame; /// "
        int WantTextInputNextFrame; /// Copied in EndFrame() from g.PlatformImeData.WanttextInput. Needs to be set for some backends (SDL3) to emit character inputs.
        ImVector!(char) TempBuffer; /// Temporary text buffer
        char[64] TempKeychordName;
    }

    /// [Internal] sizeof() ~ 112
    /// We use the terminology "Enabled" to refer to a column that is not Hidden by user/api.
    /// We use the terminology "Clipped" to refer to a column that is out of sight because of scrolling/clipping.
    /// This is in contrast with some user-facing api such as IsItemVisible() / IsRectVisible() which use "Visible" to mean "not clipped".
    struct ImGuiTableColumn {
        ImGuiTableColumnFlags Flags; /// Flags after some patching (not directly same as provided by user). See ImGuiTableColumnFlags_
        float WidthGiven; /// Final/actual width visible == (MaxX - MinX), locked in TableUpdateLayout(). May be > WidthRequest to honor minimum width, may be < WidthRequest to honor shrinking columns down in tight space.
        float MinX; /// Absolute positions
        float MaxX;
        float WidthRequest; /// Master width absolute value when !(Flags & _WidthStretch). When Stretch this is derived every frame from StretchWeight in TableUpdateLayout()
        float WidthAuto; /// Automatic width
        float WidthMax; /// Maximum width (FIXME: overwritten by each instance)
        float StretchWeight; /// Master width weight when (Flags & _WidthStretch). Often around ~1.0f initially.
        float InitStretchWeightOrWidth; /// Value passed to TableSetupColumn(). For Width it is a content width (_without padding_).
        ImRect ClipRect; /// Clipping rectangle for the column
        ImGuiID UserID; /// Optional, value passed to TableSetupColumn()
        float WorkMinX; /// Contents region min ~(MinX + CellPaddingX + CellSpacingX1) == cursor start position when entering column
        float WorkMaxX; /// Contents region max ~(MaxX - CellPaddingX - CellSpacingX2)
        float ItemWidth; /// Current item width for the column, preserved across rows
        float ContentMaxXFrozen; /// Contents maximum position for frozen rows (apart from headers), from which we can infer content width.
        float ContentMaxXUnfrozen;
        float ContentMaxXHeadersUsed; /// Contents maximum position for headers rows (regardless of freezing). TableHeader() automatically softclip itself + report ideal desired size, to avoid creating extraneous draw calls
        float ContentMaxXHeadersIdeal;
        ImS16 NameOffset; /// Offset into parent ColumnsNames[]
        ImGuiTableColumnIdx DisplayOrder; /// Index within Table's IndexToDisplayOrder[] (column may be reordered by users)
        ImGuiTableColumnIdx IndexWithinEnabledSet; /// Index within enabled/visible set (<= IndexToDisplayOrder)
        ImGuiTableColumnIdx PrevEnabledColumn; /// Index of prev enabled/visible column within Columns[], -1 if first enabled/visible column
        ImGuiTableColumnIdx NextEnabledColumn; /// Index of next enabled/visible column within Columns[], -1 if last enabled/visible column
        ImGuiTableColumnIdx SortOrder; /// Index of this column within sort specs, -1 if not sorting on this column, 0 for single-sort, may be >0 on multi-sort
        ImGuiTableDrawChannelIdx DrawChannelCurrent; /// Index within DrawSplitter.Channels[]
        ImGuiTableDrawChannelIdx DrawChannelFrozen; /// Draw channels for frozen rows (often headers)
        ImGuiTableDrawChannelIdx DrawChannelUnfrozen; /// Draw channels for unfrozen rows
        bool IsEnabled; /// IsUserEnabled && (Flags & ImGuiTableColumnFlags_Disabled) == 0
        bool IsUserEnabled; /// Is the column not marked Hidden by the user? (unrelated to being off view, e.g. clipped by scrolling).
        bool IsUserEnabledNextFrame;
        bool IsVisibleX; /// Is actually in view (e.g. overlapping the host window clipping rectangle, not scrolled).
        bool IsVisibleY;
        bool IsRequestOutput; /// Return value for TableSetColumnIndex() / TableNextColumn(): whether we request user to output contents or not.
        bool IsSkipItems; /// Do we want item submissions to this column to be completely ignored (no layout will happen).
        bool IsPreserveWidthAuto;
        ImS8 NavLayerCurrent; /// ImGuiNavLayer in 1 byte
        ImU8 AutoFitQueue; /// Queue of 8 values for the next 8 frames to request auto-fit
        ImU8 CannotSkipItemsQueue; /// Queue of 8 values for the next 8 frames to disable Clipped/SkipItem
        ImU8 SortDirection; /// ImGuiSortDirection_Ascending or ImGuiSortDirection_Descending
        ImU8 SortDirectionsAvailCount; /// Number of available sort directions (0 to 3)
        ImU8 SortDirectionsAvailMask; /// Mask of available sort directions (1-bit each)
        ImU8 SortDirectionsAvailList; /// Ordered list of available sort directions (2-bits each, total 8-bits)
    }

    /// Sorting specifications for a table (often handling sort specs for a single column, occasionally more)
    /// Obtained by calling TableGetSortSpecs().
    /// When 'SpecsDirty == true' you can sort your data. It will be true with sorting specs have changed since last call, or the first time.
    /// Make sure to set 'SpecsDirty = false' after sorting, else you may wastefully sort your data every frame!
    struct ImGuiTableSortSpecs {
        const ImGuiTableColumnSortSpecs* Specs; /// Pointer to sort spec array.
        int SpecsCount; /// Sort spec count. Most often 1. May be > 1 when ImGuiTableFlags_SortMulti is enabled. May be == 0 when ImGuiTableFlags_SortTristate is enabled.
        bool SpecsDirty; /// Set to true when specs have changed since last time! Use this to sort again, then clear the flag.
    }

    /// Packed rectangle lookup entry (we need an indirection to allow removing/reordering rectangles)
    /// User are returned ImFontAtlasRectId values which are meant to be persistent.
    /// We handle this with an indirection. While Rects[] may be in theory shuffled, compacted etc., RectsIndex[] cannot it is keyed by ImFontAtlasRectId.
    /// RectsIndex[] is used both as an index into Rects[] and an index into itself. This is basically a free-list. See ImFontAtlasBuildAllocRectIndexEntry() code.
    /// Having this also makes it easier to e.g. sort rectangles during repack.
    struct ImFontAtlasRectEntry {
        int TargetIndex; /// When Used: ImFontAtlasRectId -> into Rects[]. When unused: index to next unused RectsIndex[] slot to consume free-list.
        int Generation; /// Increased each time the entry is reused for a new rectangle.
        uint IsUsed;
    }

    /// Sorting specification for one column of a table (sizeof == 12 bytes)
    struct ImGuiTableColumnSortSpecs {
        ImGuiID ColumnUserID; /// User id of the column (if specified by a TableSetupColumn() call)
        ImS16 ColumnIndex; /// Index of the column
        ImS16 SortOrder; /// Index within parent ImGuiTableSortSpecs (always stored in order starting from 0, tables sorted on a single criteria will always have a 0 here)
        ImGuiSortDirection SortDirection; /// ImGuiSortDirection_Ascending or ImGuiSortDirection_Descending
    }

    /// Temporary storage for multi-select
    struct ImGuiMultiSelectTempData {
        ImGuiMultiSelectIO IO; /// MUST BE FIRST FIELD. Requests are set and returned by BeginMultiSelect()/EndMultiSelect() + written to by user during the loop.
        ImGuiMultiSelectState* Storage;
        ImGuiID FocusScopeId; /// Copied from g.CurrentFocusScopeId (unless another selection scope was pushed manually)
        ImGuiMultiSelectFlags Flags;
        ImVec2 ScopeRectMin;
        ImVec2 BackupCursorMaxPos;
        ImGuiSelectionUserData LastSubmittedItem; /// Copy of last submitted item data, used to merge output ranges.
        ImGuiID BoxSelectId;
        ImGuiKeyChord KeyMods;
        ImS8 LoopRequestSetAll; /// -1: no operation, 0: clear all, 1: select all.
        bool IsEndIO; /// Set when switching IO from BeginMultiSelect() to EndMultiSelect() state.
        bool IsFocused; /// Set if currently focusing the selection scope (any item of the selection). May be used if you have custom shortcut associated to selection.
        bool IsKeyboardSetRange; /// Set by BeginMultiSelect() when using Shift+Navigation. Because scrolling may be affected we can't afford a frame of lag with Shift+Navigation.
        bool NavIdPassedBy;
        bool RangeSrcPassedBy; /// Set by the item that matches RangeSrcItem.
        bool RangeDstPassedBy; /// Set by the item that matches NavJustMovedToId when IsSetRange is set.
    }

    /// Helper: Execute a block of code at maximum once a frame. Convenient if you want to quickly create a UI within deep-nested code that runs multiple times every frame.
    /// Usage: static ImGuiOnceUponAFrame oaf; if (oaf) ImGui::Text("This will be called only once per frame");
    struct ImGuiOnceUponAFrame {
        int RefFrame;
    }

    /// Windows data saved in imgui.ini file
    /// Because we never destroy or rename ImGuiWindowSettings, we can store the names in a separate buffer easily.
    /// (this is designed to be stored in a ImChunkStream buffer, with the variable-length Name following our structure)
    struct ImGuiWindowSettings {
        ImGuiID ID;
        ImVec2ih Pos; /// NB: Settings position are stored RELATIVE to the viewport! Whereas runtime ones are absolute positions.
        ImVec2ih Size;
        ImVec2ih ViewportPos;
        ImGuiID ViewportId;
        ImGuiID DockId; /// ID of last known DockNode (even if the DockNode is invisible because it has only 1 active window), or 0 if none.
        ImGuiID ClassId; /// ID of window class if specified
        short DockOrder; /// Order of the last time the window was visible within its DockNode. This is used to reorder windows that are reappearing on the same frame. Same value between windows that were active and windows that were none are possible.
        bool Collapsed;
        bool IsChild;
        bool WantApply; /// Set when loaded from .ini data (to enable merging/loading .ini data into an already running context)
        bool WantDelete; /// Set to invalidate/delete the settings entry
    }

    /// (Optional) Support for IME (Input Method Editor) via the platform_io.Platform_SetImeDataFn() function. Handler is called during EndFrame().
    struct ImGuiPlatformImeData {
        bool WantVisible; /// A widget wants the IME to be visible.
        bool WantTextInput; /// A widget wants text input, not necessarily IME to be visible. This is automatically set to the upcoming value of io.WantTextInput.
        ImVec2 InputPos; /// Position of input cursor (for IME).
        float InputLineHeight; /// Line height (for IME).
        ImGuiID ViewportId; /// ID of platform window/viewport.
    }

    /// Draw command list
    /// This is the low-level list of polygons that ImGui:: functions are filling. At the end of the frame,
    /// all command lists are passed to your ImGuiIO::RenderDrawListFn function for rendering.
    /// Each dear imgui window contains its own ImDrawList. You can use ImGui::GetWindowDrawList() to
    /// access the current window draw list and draw custom primitives.
    /// You can interleave normal ImGui:: calls and adding primitives to the current draw list.
    /// In single viewport mode, top-left is == GetMainViewport()->Pos (generally 0,0), bottom-right is == GetMainViewport()->Pos+Size (generally io.DisplaySize).
    /// You are totally free to apply whatever transformation matrix you want to the data (depending on the use of the transformation you may want to apply it to ClipRect as well!)
    /// Important: Primitives are always added to the list and not culled (culling is done at higher-level by ImGui:: functions), if you use this API a lot consider coarse culling your drawn objects.
    struct ImDrawList {
         
            /// This is what you have to render
        ImVector!(ImDrawCmd) CmdBuffer; /// Draw commands. Typically 1 command = 1 GPU draw call, unless the command is a callback.
        ImVector!(ImDrawIdx) IdxBuffer; /// Index buffer. Each command consume ImDrawCmd::ElemCount of those
        ImVector!(ImDrawVert) VtxBuffer; /// Vertex buffer.
        ImDrawListFlags Flags; /// Flags, you may poke into these to adjust anti-aliasing settings per-primitive.
             /// [Internal, used while building lists]
        uint _VtxCurrentIdx; /// [Internal] generally == VtxBuffer.Size unless we are past 64K vertices, in which case this gets reset to 0.
        ImDrawListSharedData* _Data; /// Pointer to shared draw data (you can use ImGui::GetDrawListSharedData() to get the one from current ImGui context)
        ImDrawVert* _VtxWritePtr; /// [Internal] point within VtxBuffer.Data after each add command (to avoid using the ImVector<> operators too much)
        ImDrawIdx* _IdxWritePtr; /// [Internal] point within IdxBuffer.Data after each add command (to avoid using the ImVector<> operators too much)
        ImVector!(ImVec2) _Path; /// [Internal] current path building
        ImDrawCmdHeader _CmdHeader; /// [Internal] template of active commands. Fields should match those of CmdBuffer.back().
        ImDrawListSplitter _Splitter; /// [Internal] for channels api (note: prefer using your own persistent instance of ImDrawListSplitter!)
        ImVector!(ImVec4) _ClipRectStack; /// [Internal]
        ImVector!(ImTextureRef) _TextureStack; /// [Internal]
        ImVector!(ImU8) _CallbacksDataBuf; /// [Internal]
        float _FringeScale; /// [Internal] anti-alias fringe is scaled by this value, this helps to keep things sharp while zooming at vertex buffer content
        const(char)* _OwnerName; /// Pointer to owner window's name for debugging
    }

    /// Storage for GetTypingSelectRequest()
    struct ImGuiTypingSelectState {
        ImGuiTypingSelectRequest Request; /// User-facing data
        char[64] SearchBuffer; /// Search buffer: no need to make dynamic as this search is very transient.
        ImGuiID FocusScope;
        int LastRequestFrame;
        float LastRequestTime;
        bool SingleCharModeLock; /// After a certain single char repeat count we lock into SingleCharMode. Two benefits: 1) buffer never fill, 2) we can provide an immediate SingleChar mode without timer elapsing.
    }

    /// Simple column measurement, currently used for MenuItem() only.. This is very short-sighted/throw-away code and NOT a generic helper.
    struct ImGuiMenuColumns {
        ImU32 TotalWidth;
        ImU32 NextTotalWidth;
        ImU16 Spacing;
        ImU16 OffsetIcon; /// Always zero for now
        ImU16 OffsetLabel; /// Offsets are locked in Update()
        ImU16 OffsetShortcut;
        ImU16 OffsetMark;
        ImU16[4] Widths; /// Width of:   Icon, Label, Shortcut, Mark  (accumulators for current frame)
    }

    struct ImGuiInputEventMouseViewport {
        ImGuiID HoveredViewportID;
    }

    /// Storage for one active tab item (sizeof() 48 bytes)
    struct ImGuiTabItem {
        ImGuiID ID;
        ImGuiTabItemFlags Flags;
        ImGuiWindow* Window; /// When TabItem is part of a DockNode's TabBar, we hold on to a window.
        int LastFrameVisible;
        int LastFrameSelected; /// This allows us to infer an ordered list of the last activated tabs with little maintenance
        float Offset; /// Position relative to beginning of tab
        float Width; /// Width currently displayed
        float ContentWidth; /// Width of label, stored during BeginTabItem() call
        float RequestedWidth; /// Width optionally requested by caller, -1.0f is unused
        ImS32 NameOffset; /// When Window==NULL, offset to name within parent ImGuiTabBar::TabsNames
        ImS16 BeginOrder; /// BeginTabItem() order, used to re-order tabs after toggling ImGuiTabBarFlags_Reorderable
        ImS16 IndexDuringLayout; /// Index only used during TabBarLayout(). Tabs gets reordered so 'Tabs[n].IndexDuringLayout == n' but may mismatch during additions.
        bool WantClose; /// Marked as closed by SetTabItemClosed()
    }

    /// FIXME: Structures in the union below need to be declared as anonymous unions appears to be an extension?
    /// Using ImVec2() would fail on Clang 'union member 'MousePos' has a non-trivial default constructor'
    struct ImGuiInputEventMousePos {
        float PosX;
        float PosY;
        ImGuiMouseSource MouseSource;
    }

    /// We don't store style.Alpha: dock_node->LastBgColor embeds it and otherwise it would only affect the docking tab, which intuitively I would say we don't want to.
    struct ImGuiWindowDockStyle {
        ImU32[ImGuiWindowDockStyleCol.COUNT] Colors;
    }


}
extern (C) @nogc nothrow {
    void ImBitVector_Clear(ImBitVector* self);
    void ImBitVector_ClearBit(ImBitVector* self, int n);
    void ImBitVector_Create(ImBitVector* self, int sz);
    void ImBitVector_SetBit(ImBitVector* self, int n);
    bool ImBitVector_TestBit(ImBitVector* self, int n);
    void ImColor_HSV(ImColor* pOut, float h, float s, float v, float a = 1.0f);
    ImColor* ImColor_ImColor_Nil();
    ImColor* ImColor_ImColor_Float(float r, float g, float b, float a = 1.0f);
    ImColor* ImColor_ImColor_Vec4(const ImVec4 col);
    ImColor* ImColor_ImColor_Int(int r, int g, int b, int a = 255);
    ImColor* ImColor_ImColor_U32(ImU32 rgba);
    void ImColor_SetHSV(ImColor* self, float h, float s, float v, float a = 1.0f);
    void ImColor_destroy(ImColor* self);
    /// == (TexRef._TexData ? TexRef._TexData->TexID : TexRef._TexID
    ImTextureID ImDrawCmd_GetTexID(ImDrawCmd* self);
    /// Also ensure our padding fields are zeroed
    ImDrawCmd* ImDrawCmd_ImDrawCmd();
    void ImDrawCmd_destroy(ImDrawCmd* self);
    ImDrawDataBuilder* ImDrawDataBuilder_ImDrawDataBuilder();
    void ImDrawDataBuilder_destroy(ImDrawDataBuilder* self);
    /// Helper to add an external draw list into an existing ImDrawData.
    void ImDrawData_AddDrawList(ImDrawData* self, ImDrawList* draw_list);
    void ImDrawData_Clear(ImDrawData* self);
    /// Helper to convert all buffers from indexed to non-indexed, in case you cannot render indexed. Note: this is slow and most likely a waste of resources. Always prefer indexed rendering!
    void ImDrawData_DeIndexAllBuffers(ImDrawData* self);
    ImDrawData* ImDrawData_ImDrawData();
    /// Helper to scale the ClipRect field of each ImDrawCmd. Use if your final output buffer is at a different scale than Dear ImGui expects, or if there is a difference between your window resolution and framebuffer resolution.
    void ImDrawData_ScaleClipRects(ImDrawData* self, const ImVec2 fb_scale);
    void ImDrawData_destroy(ImDrawData* self);
    ImDrawListSharedData* ImDrawListSharedData_ImDrawListSharedData();
    void ImDrawListSharedData_SetCircleTessellationMaxError(ImDrawListSharedData* self, float max_error);
    void ImDrawListSharedData_destroy(ImDrawListSharedData* self);
    /// Do not clear Channels[] so our allocations are reused next frame
    void ImDrawListSplitter_Clear(ImDrawListSplitter* self);
    void ImDrawListSplitter_ClearFreeMemory(ImDrawListSplitter* self);
    ImDrawListSplitter* ImDrawListSplitter_ImDrawListSplitter();
    void ImDrawListSplitter_Merge(ImDrawListSplitter* self, ImDrawList* draw_list);
    void ImDrawListSplitter_SetCurrentChannel(ImDrawListSplitter* self, ImDrawList* draw_list, int channel_idx);
    void ImDrawListSplitter_Split(ImDrawListSplitter* self, ImDrawList* draw_list, int count);
    void ImDrawListSplitter_destroy(ImDrawListSplitter* self);
    /// Cubic Bezier (4 control points)
    void ImDrawList_AddBezierCubic(ImDrawList* self, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, ImU32 col, float thickness, int num_segments = 0);
    /// Quadratic Bezier (3 control points)
    void ImDrawList_AddBezierQuadratic(ImDrawList* self, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, ImU32 col, float thickness, int num_segments = 0);
    void ImDrawList_AddCallback(ImDrawList* self, ImDrawCallback callback, void* userdata, size_t userdata_size = 0);
    void ImDrawList_AddCircle(ImDrawList* self, const ImVec2 center, float radius, ImU32 col, int num_segments = 0, float thickness = 1.0f);
    void ImDrawList_AddCircleFilled(ImDrawList* self, const ImVec2 center, float radius, ImU32 col, int num_segments = 0);
    void ImDrawList_AddConcavePolyFilled(ImDrawList* self, const ImVec2* points, int num_points, ImU32 col);
    void ImDrawList_AddConvexPolyFilled(ImDrawList* self, const ImVec2* points, int num_points, ImU32 col);
    /// This is useful if you need to forcefully create a new draw call (to allow for dependent rendering / blending). Otherwise primitives are merged into the same draw-call as much as possible
    void ImDrawList_AddDrawCmd(ImDrawList* self);
    void ImDrawList_AddEllipse(ImDrawList* self, const ImVec2 center, const ImVec2 radius, ImU32 col, float rot = 0.0f, int num_segments = 0, float thickness = 1.0f);
    void ImDrawList_AddEllipseFilled(ImDrawList* self, const ImVec2 center, const ImVec2 radius, ImU32 col, float rot = 0.0f, int num_segments = 0);
    void ImDrawList_AddImage(ImDrawList* self, ImTextureRef tex_ref, const ImVec2 p_min, const ImVec2 p_max, const ImVec2 uv_min = ImVec2(0,0), const ImVec2 uv_max = ImVec2(1,1), ImU32 col = 4294967295);
    void ImDrawList_AddImageQuad(ImDrawList* self, ImTextureRef tex_ref, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, const ImVec2 uv1 = ImVec2(0,0), const ImVec2 uv2 = ImVec2(1,0), const ImVec2 uv3 = ImVec2(1,1), const ImVec2 uv4 = ImVec2(0,1), ImU32 col = 4294967295);
    void ImDrawList_AddImageRounded(ImDrawList* self, ImTextureRef tex_ref, const ImVec2 p_min, const ImVec2 p_max, const ImVec2 uv_min, const ImVec2 uv_max, ImU32 col, float rounding, ImDrawFlags flags = ImDrawFlags.None);
    void ImDrawList_AddLine(ImDrawList* self, const ImVec2 p1, const ImVec2 p2, ImU32 col, float thickness = 1.0f);
    void ImDrawList_AddNgon(ImDrawList* self, const ImVec2 center, float radius, ImU32 col, int num_segments, float thickness = 1.0f);
    void ImDrawList_AddNgonFilled(ImDrawList* self, const ImVec2 center, float radius, ImU32 col, int num_segments);
    void ImDrawList_AddPolyline(ImDrawList* self, const ImVec2* points, int num_points, ImU32 col, ImDrawFlags flags, float thickness);
    void ImDrawList_AddQuad(ImDrawList* self, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, ImU32 col, float thickness = 1.0f);
    void ImDrawList_AddQuadFilled(ImDrawList* self, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, ImU32 col);
    /// a: upper-left, b: lower-right (== upper-left + size)
    void ImDrawList_AddRect(ImDrawList* self, const ImVec2 p_min, const ImVec2 p_max, ImU32 col, float rounding = 0.0f, ImDrawFlags flags = ImDrawFlags.None, float thickness = 1.0f);
    /// a: upper-left, b: lower-right (== upper-left + size)
    void ImDrawList_AddRectFilled(ImDrawList* self, const ImVec2 p_min, const ImVec2 p_max, ImU32 col, float rounding = 0.0f, ImDrawFlags flags = ImDrawFlags.None);
    void ImDrawList_AddRectFilledMultiColor(ImDrawList* self, const ImVec2 p_min, const ImVec2 p_max, ImU32 col_upr_left, ImU32 col_upr_right, ImU32 col_bot_right, ImU32 col_bot_left);
    void ImDrawList_AddText_Vec2(ImDrawList* self, const ImVec2 pos, ImU32 col, const(char)* text_begin, const(char)* text_end = null);
    void ImDrawList_AddText_FontPtr(ImDrawList* self, ImFont* font, float font_size, const ImVec2 pos, ImU32 col, const(char)* text_begin, const(char)* text_end = null, float wrap_width = 0.0f, const(ImVec4)* cpu_fine_clip_rect = null);
    void ImDrawList_AddTriangle(ImDrawList* self, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, ImU32 col, float thickness = 1.0f);
    void ImDrawList_AddTriangleFilled(ImDrawList* self, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, ImU32 col);
    void ImDrawList_ChannelsMerge(ImDrawList* self);
    void ImDrawList_ChannelsSetCurrent(ImDrawList* self, int n);
    void ImDrawList_ChannelsSplit(ImDrawList* self, int count);
    /// Create a clone of the CmdBuffer/IdxBuffer/VtxBuffer.
    ImDrawList* ImDrawList_CloneOutput(ImDrawList* self);
    void ImDrawList_GetClipRectMax(ImVec2* pOut, ImDrawList* self);
    void ImDrawList_GetClipRectMin(ImVec2* pOut, ImDrawList* self);
    ImDrawList* ImDrawList_ImDrawList(ImDrawListSharedData* shared_data);
    void ImDrawList_PathArcTo(ImDrawList* self, const ImVec2 center, float radius, float a_min, float a_max, int num_segments = 0);
    /// Use precomputed angles for a 12 steps circle
    void ImDrawList_PathArcToFast(ImDrawList* self, const ImVec2 center, float radius, int a_min_of_12, int a_max_of_12);
    /// Cubic Bezier (4 control points)
    void ImDrawList_PathBezierCubicCurveTo(ImDrawList* self, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, int num_segments = 0);
    /// Quadratic Bezier (3 control points)
    void ImDrawList_PathBezierQuadraticCurveTo(ImDrawList* self, const ImVec2 p2, const ImVec2 p3, int num_segments = 0);
    void ImDrawList_PathClear(ImDrawList* self);
    /// Ellipse
    void ImDrawList_PathEllipticalArcTo(ImDrawList* self, const ImVec2 center, const ImVec2 radius, float rot, float a_min, float a_max, int num_segments = 0);
    void ImDrawList_PathFillConcave(ImDrawList* self, ImU32 col);
    void ImDrawList_PathFillConvex(ImDrawList* self, ImU32 col);
    void ImDrawList_PathLineTo(ImDrawList* self, const ImVec2 pos);
    void ImDrawList_PathLineToMergeDuplicate(ImDrawList* self, const ImVec2 pos);
    void ImDrawList_PathRect(ImDrawList* self, const ImVec2 rect_min, const ImVec2 rect_max, float rounding = 0.0f, ImDrawFlags flags = ImDrawFlags.None);
    void ImDrawList_PathStroke(ImDrawList* self, ImU32 col, ImDrawFlags flags = ImDrawFlags.None, float thickness = 1.0f);
    void ImDrawList_PopClipRect(ImDrawList* self);
    void ImDrawList_PopTexture(ImDrawList* self);
    void ImDrawList_PrimQuadUV(ImDrawList* self, const ImVec2 a, const ImVec2 b, const ImVec2 c, const ImVec2 d, const ImVec2 uv_a, const ImVec2 uv_b, const ImVec2 uv_c, const ImVec2 uv_d, ImU32 col);
    /// Axis aligned rectangle (composed of two triangles)
    void ImDrawList_PrimRect(ImDrawList* self, const ImVec2 a, const ImVec2 b, ImU32 col);
    void ImDrawList_PrimRectUV(ImDrawList* self, const ImVec2 a, const ImVec2 b, const ImVec2 uv_a, const ImVec2 uv_b, ImU32 col);
    void ImDrawList_PrimReserve(ImDrawList* self, int idx_count, int vtx_count);
    void ImDrawList_PrimUnreserve(ImDrawList* self, int idx_count, int vtx_count);
    /// Write vertex with unique index
    void ImDrawList_PrimVtx(ImDrawList* self, const ImVec2 pos, const ImVec2 uv, ImU32 col);
    void ImDrawList_PrimWriteIdx(ImDrawList* self, ImDrawIdx idx);
    void ImDrawList_PrimWriteVtx(ImDrawList* self, const ImVec2 pos, const ImVec2 uv, ImU32 col);
    /// Render-level scissoring. This is passed down to your render function but not used for CPU-side coarse clipping. Prefer using higher-level ImGui::PushClipRect() to affect logic (hit-testing and widget culling)
    void ImDrawList_PushClipRect(ImDrawList* self, const ImVec2 clip_rect_min, const ImVec2 clip_rect_max, bool intersect_with_current_clip_rect = false);
    void ImDrawList_PushClipRectFullScreen(ImDrawList* self);
    void ImDrawList_PushTexture(ImDrawList* self, ImTextureRef tex_ref);
    int ImDrawList__CalcCircleAutoSegmentCount(ImDrawList* self, float radius);
    void ImDrawList__ClearFreeMemory(ImDrawList* self);
    void ImDrawList__OnChangedClipRect(ImDrawList* self);
    void ImDrawList__OnChangedTexture(ImDrawList* self);
    void ImDrawList__OnChangedVtxOffset(ImDrawList* self);
    void ImDrawList__PathArcToFastEx(ImDrawList* self, const ImVec2 center, float radius, int a_min_sample, int a_max_sample, int a_step);
    void ImDrawList__PathArcToN(ImDrawList* self, const ImVec2 center, float radius, float a_min, float a_max, int num_segments);
    void ImDrawList__PopUnusedDrawCmd(ImDrawList* self);
    void ImDrawList__ResetForNewFrame(ImDrawList* self);
    void ImDrawList__SetDrawListSharedData(ImDrawList* self, ImDrawListSharedData* data);
    void ImDrawList__SetTexture(ImDrawList* self, ImTextureRef tex_ref);
    void ImDrawList__TryMergeDrawCmds(ImDrawList* self);
    void ImDrawList_destroy(ImDrawList* self);
    ImFontAtlasBuilder* ImFontAtlasBuilder_ImFontAtlasBuilder();
    void ImFontAtlasBuilder_destroy(ImFontAtlasBuilder* self);
    ImFontAtlasRect* ImFontAtlasRect_ImFontAtlasRect();
    void ImFontAtlasRect_destroy(ImFontAtlasRect* self);
    /// Register a rectangle. Return -1 (ImFontAtlasRectId_Invalid) on error.
    ImFontAtlasRectId ImFontAtlas_AddCustomRect(ImFontAtlas* self, int width, int height, ImFontAtlasRect* out_r = null);
    ImFont* ImFontAtlas_AddFont(ImFontAtlas* self, const ImFontConfig* font_cfg);
    ImFont* ImFontAtlas_AddFontDefault(ImFontAtlas* self, const ImFontConfig* font_cfg = null);
    ImFont* ImFontAtlas_AddFontFromFileTTF(ImFontAtlas* self, const(char)* filename, float size_pixels = 0.0f, const ImFontConfig* font_cfg = null, const(ImWchar)* glyph_ranges = null);
    /// 'compressed_font_data_base85' still owned by caller. Compress with binary_to_compressed_c.cpp with -base85 parameter.
    ImFont* ImFontAtlas_AddFontFromMemoryCompressedBase85TTF(ImFontAtlas* self, const(char)* compressed_font_data_base85, float size_pixels = 0.0f, const ImFontConfig* font_cfg = null, const(ImWchar)* glyph_ranges = null);
    /// 'compressed_font_data' still owned by caller. Compress with binary_to_compressed_c.cpp.
    ImFont* ImFontAtlas_AddFontFromMemoryCompressedTTF(ImFontAtlas* self, const void* compressed_font_data, int compressed_font_data_size, float size_pixels = 0.0f, const ImFontConfig* font_cfg = null, const(ImWchar)* glyph_ranges = null);
    /// Note: Transfer ownership of 'ttf_data' to ImFontAtlas! Will be deleted after destruction of the atlas. Set font_cfg->FontDataOwnedByAtlas=false to keep ownership of your data and it won't be freed.
    ImFont* ImFontAtlas_AddFontFromMemoryTTF(ImFontAtlas* self, void* font_data, int font_data_size, float size_pixels = 0.0f, const ImFontConfig* font_cfg = null, const(ImWchar)* glyph_ranges = null);
    /// Clear everything (input fonts, output glyphs/textures)
    void ImFontAtlas_Clear(ImFontAtlas* self);
    /// [OBSOLETE] Clear input+output font data (same as ClearInputData() + glyphs storage, UV coordinates).
    void ImFontAtlas_ClearFonts(ImFontAtlas* self);
    /// [OBSOLETE] Clear input data (all ImFontConfig structures including sizes, TTF data, glyph ranges, etc.) = all the data used to build the texture and fonts.
    void ImFontAtlas_ClearInputData(ImFontAtlas* self);
    /// [OBSOLETE] Clear CPU-side copy of the texture data. Saves RAM once the texture has been copied to graphics memory.
    void ImFontAtlas_ClearTexData(ImFontAtlas* self);
    /// Compact cached glyphs and texture.
    void ImFontAtlas_CompactCache(ImFontAtlas* self);
    /// Get rectangle coordinates for current texture. Valid immediately, never store this (read above)!
    bool ImFontAtlas_GetCustomRect(ImFontAtlas* self, ImFontAtlasRectId id, ImFontAtlasRect* out_r);
    /// Basic Latin, Extended Latin
    const(ImWchar)* ImFontAtlas_GetGlyphRangesDefault(ImFontAtlas* self);
    ImFontAtlas* ImFontAtlas_ImFontAtlas();
    /// Unregister a rectangle. Existing pixels will stay in texture until resized / garbage collected.
    void ImFontAtlas_RemoveCustomRect(ImFontAtlas* self, ImFontAtlasRectId id);
    void ImFontAtlas_RemoveFont(ImFontAtlas* self, ImFont* font);
    void ImFontAtlas_destroy(ImFontAtlas* self);
    void ImFontBaked_ClearOutputData(ImFontBaked* self);
    /// Return U+FFFD glyph if requested glyph doesn't exists.
    ImFontGlyph* ImFontBaked_FindGlyph(ImFontBaked* self, ImWchar c);
    /// Return NULL if glyph doesn't exist
    ImFontGlyph* ImFontBaked_FindGlyphNoFallback(ImFontBaked* self, ImWchar c);
    float ImFontBaked_GetCharAdvance(ImFontBaked* self, ImWchar c);
    ImFontBaked* ImFontBaked_ImFontBaked();
    bool ImFontBaked_IsGlyphLoaded(ImFontBaked* self, ImWchar c);
    void ImFontBaked_destroy(ImFontBaked* self);
    ImFontConfig* ImFontConfig_ImFontConfig();
    void ImFontConfig_destroy(ImFontConfig* self);
    /// Add character
    void ImFontGlyphRangesBuilder_AddChar(ImFontGlyphRangesBuilder* self, ImWchar c);
    /// Add ranges, e.g. builder.AddRanges(ImFontAtlas::GetGlyphRangesDefault()) to force add all of ASCII/Latin+Ext
    void ImFontGlyphRangesBuilder_AddRanges(ImFontGlyphRangesBuilder* self, const(ImWchar)* ranges);
    /// Add string (each character of the UTF-8 string are added)
    void ImFontGlyphRangesBuilder_AddText(ImFontGlyphRangesBuilder* self, const(char)* text, const(char)* text_end = null);
    /// Output new ranges
    void ImFontGlyphRangesBuilder_BuildRanges(ImFontGlyphRangesBuilder* self, ImVector!(ImWchar)* out_ranges);
    void ImFontGlyphRangesBuilder_Clear(ImFontGlyphRangesBuilder* self);
    /// Get bit n in the array
    bool ImFontGlyphRangesBuilder_GetBit(ImFontGlyphRangesBuilder* self, size_t n);
    ImFontGlyphRangesBuilder* ImFontGlyphRangesBuilder_ImFontGlyphRangesBuilder();
    /// Set bit n in the array
    void ImFontGlyphRangesBuilder_SetBit(ImFontGlyphRangesBuilder* self, size_t n);
    void ImFontGlyphRangesBuilder_destroy(ImFontGlyphRangesBuilder* self);
    ImFontGlyph* ImFontGlyph_ImFontGlyph();
    void ImFontGlyph_destroy(ImFontGlyph* self);
    ImFontLoader* ImFontLoader_ImFontLoader();
    void ImFontLoader_destroy(ImFontLoader* self);
    /// Makes 'from_codepoint' character points to 'to_codepoint' glyph.
    void ImFont_AddRemapChar(ImFont* self, ImWchar from_codepoint, ImWchar to_codepoint);
    /// utf8
    void ImFont_CalcTextSizeA(ImVec2* pOut, ImFont* self, float size, float max_width, float wrap_width, const(char)* text_begin, const(char)* text_end = null, const char** remaining = null);
    const(char)* ImFont_CalcWordWrapPosition(ImFont* self, float size, const(char)* text, const(char)* text_end, float wrap_width);
    void ImFont_ClearOutputData(ImFont* self);
    /// Fill ImFontConfig::Name.
    const(char)* ImFont_GetDebugName(ImFont* self);
    /// Get or create baked data for given size
    ImFontBaked* ImFont_GetFontBaked(ImFont* self, float font_size, float density = -1.0f);
    ImFont* ImFont_ImFont();
    bool ImFont_IsGlyphInFont(ImFont* self, ImWchar c);
    bool ImFont_IsGlyphRangeUnused(ImFont* self, uint c_begin, uint c_last);
    bool ImFont_IsLoaded(ImFont* self);
    void ImFont_RenderChar(ImFont* self, ImDrawList* draw_list, float size, const ImVec2 pos, ImU32 col, ImWchar c, const(ImVec4)* cpu_fine_clip = null);
    void ImFont_RenderText(ImFont* self, ImDrawList* draw_list, float size, const ImVec2 pos, ImU32 col, const ImVec4 clip_rect, const(char)* text_begin, const(char)* text_end, float wrap_width = 0.0f, bool cpu_fine_clip = false);
    void ImFont_destroy(ImFont* self);
    ImGuiBoxSelectState* ImGuiBoxSelectState_ImGuiBoxSelectState();
    void ImGuiBoxSelectState_destroy(ImGuiBoxSelectState* self);
    ImGuiComboPreviewData* ImGuiComboPreviewData_ImGuiComboPreviewData();
    void ImGuiComboPreviewData_destroy(ImGuiComboPreviewData* self);
    ImGuiContextHook* ImGuiContextHook_ImGuiContextHook();
    void ImGuiContextHook_destroy(ImGuiContextHook* self);
    ImGuiContext* ImGuiContext_ImGuiContext(ImFontAtlas* shared_font_atlas);
    void ImGuiContext_destroy(ImGuiContext* self);
    ImGuiDebugAllocInfo* ImGuiDebugAllocInfo_ImGuiDebugAllocInfo();
    void ImGuiDebugAllocInfo_destroy(ImGuiDebugAllocInfo* self);
    ImGuiDockContext* ImGuiDockContext_ImGuiDockContext();
    void ImGuiDockContext_destroy(ImGuiDockContext* self);
    ImGuiDockNodeSettings* ImGuiDockNodeSettings_ImGuiDockNodeSettings();
    void ImGuiDockNodeSettings_destroy(ImGuiDockNodeSettings* self);
    ImGuiDockNode* ImGuiDockNode_ImGuiDockNode(ImGuiID id);
    bool ImGuiDockNode_IsCentralNode(ImGuiDockNode* self);
    bool ImGuiDockNode_IsDockSpace(ImGuiDockNode* self);
    bool ImGuiDockNode_IsEmpty(ImGuiDockNode* self);
    bool ImGuiDockNode_IsFloatingNode(ImGuiDockNode* self);
    /// Hidden tab bar can be shown back by clicking the small triangle
    bool ImGuiDockNode_IsHiddenTabBar(ImGuiDockNode* self);
    bool ImGuiDockNode_IsLeafNode(ImGuiDockNode* self);
    /// Never show a tab bar
    bool ImGuiDockNode_IsNoTabBar(ImGuiDockNode* self);
    bool ImGuiDockNode_IsRootNode(ImGuiDockNode* self);
    bool ImGuiDockNode_IsSplitNode(ImGuiDockNode* self);
    void ImGuiDockNode_Rect(ImRect* pOut, ImGuiDockNode* self);
    void ImGuiDockNode_SetLocalFlags(ImGuiDockNode* self, ImGuiDockNodeFlags flags);
    void ImGuiDockNode_UpdateMergedFlags(ImGuiDockNode* self);
    void ImGuiDockNode_destroy(ImGuiDockNode* self);
    ImGuiDockPreviewData* ImGuiDockPreviewData_ImGuiDockPreviewData();
    void ImGuiDockPreviewData_destroy(ImGuiDockPreviewData* self);
    ImGuiDockRequest* ImGuiDockRequest_ImGuiDockRequest();
    void ImGuiDockRequest_destroy(ImGuiDockRequest* self);
    ImGuiErrorRecoveryState* ImGuiErrorRecoveryState_ImGuiErrorRecoveryState();
    void ImGuiErrorRecoveryState_destroy(ImGuiErrorRecoveryState* self);
    ImGuiIDStackTool* ImGuiIDStackTool_ImGuiIDStackTool();
    void ImGuiIDStackTool_destroy(ImGuiIDStackTool* self);
    /// Queue a gain/loss of focus for the application (generally based on OS/platform focus of your window)
    void ImGuiIO_AddFocusEvent(ImGuiIO* self, bool focused);
    /// Queue a new character input
    void ImGuiIO_AddInputCharacter(ImGuiIO* self, uint c);
    /// Queue a new character input from a UTF-16 character, it can be a surrogate
    void ImGuiIO_AddInputCharacterUTF16(ImGuiIO* self, ImWchar16 c);
    /// Queue a new characters input from a UTF-8 string
    void ImGuiIO_AddInputCharactersUTF8(ImGuiIO* self, const(char)* str);
    /// Queue a new key down/up event for analog values (e.g. ImGuiKey_Gamepad_ values). Dead-zones should be handled by the backend.
    void ImGuiIO_AddKeyAnalogEvent(ImGuiIO* self, ImGuiKey key, bool down, float v);
    /// Queue a new key down/up event. Key should be "translated" (as in, generally ImGuiKey_A matches the key end-user would use to emit an 'A' character)
    void ImGuiIO_AddKeyEvent(ImGuiIO* self, ImGuiKey key, bool down);
    /// Queue a mouse button change
    void ImGuiIO_AddMouseButtonEvent(ImGuiIO* self, int button, bool down);
    /// Queue a mouse position update. Use -FLT_MAX,-FLT_MAX to signify no mouse (e.g. app not focused and not hovered)
    void ImGuiIO_AddMousePosEvent(ImGuiIO* self, float x, float y);
    /// Queue a mouse source change (Mouse/TouchScreen/Pen)
    void ImGuiIO_AddMouseSourceEvent(ImGuiIO* self, ImGuiMouseSource source);
    /// Queue a mouse hovered viewport. Requires backend to set ImGuiBackendFlags_HasMouseHoveredViewport to call this (for multi-viewport support).
    void ImGuiIO_AddMouseViewportEvent(ImGuiIO* self, ImGuiID id);
    /// Queue a mouse wheel update. wheel_y<0: scroll down, wheel_y>0: scroll up, wheel_x<0: scroll right, wheel_x>0: scroll left.
    void ImGuiIO_AddMouseWheelEvent(ImGuiIO* self, float wheel_x, float wheel_y);
    /// Clear all incoming events.
    void ImGuiIO_ClearEventsQueue(ImGuiIO* self);
    /// Clear current keyboard/gamepad state + current frame text input buffer. Equivalent to releasing all keys/buttons.
    void ImGuiIO_ClearInputKeys(ImGuiIO* self);
    /// Clear current mouse state.
    void ImGuiIO_ClearInputMouse(ImGuiIO* self);
    ImGuiIO* ImGuiIO_ImGuiIO();
    /// Set master flag for accepting key/mouse/text events (default to true). Useful if you have native dialog boxes that are interrupting your application loop/refresh, and you want to disable events being queued while your app is frozen.
    void ImGuiIO_SetAppAcceptingEvents(ImGuiIO* self, bool accepting_events);
    /// [Optional] Specify index for legacy <1.87 IsKeyXXX() functions with native indices + specify native keycode, scancode.
    void ImGuiIO_SetKeyEventNativeData(ImGuiIO* self, ImGuiKey key, int native_keycode, int native_scancode, int native_legacy_index = -1);
    void ImGuiIO_destroy(ImGuiIO* self);
    ImGuiInputEvent* ImGuiInputEvent_ImGuiInputEvent();
    void ImGuiInputEvent_destroy(ImGuiInputEvent* self);
    void ImGuiInputTextCallbackData_ClearSelection(ImGuiInputTextCallbackData* self);
    void ImGuiInputTextCallbackData_DeleteChars(ImGuiInputTextCallbackData* self, int pos, int bytes_count);
    bool ImGuiInputTextCallbackData_HasSelection(ImGuiInputTextCallbackData* self);
    ImGuiInputTextCallbackData* ImGuiInputTextCallbackData_ImGuiInputTextCallbackData();
    void ImGuiInputTextCallbackData_InsertChars(ImGuiInputTextCallbackData* self, int pos, const(char)* text, const(char)* text_end = null);
    void ImGuiInputTextCallbackData_SelectAll(ImGuiInputTextCallbackData* self);
    void ImGuiInputTextCallbackData_destroy(ImGuiInputTextCallbackData* self);
    void ImGuiInputTextDeactivatedState_ClearFreeMemory(ImGuiInputTextDeactivatedState* self);
    ImGuiInputTextDeactivatedState* ImGuiInputTextDeactivatedState_ImGuiInputTextDeactivatedState();
    void ImGuiInputTextDeactivatedState_destroy(ImGuiInputTextDeactivatedState* self);
    void ImGuiInputTextState_ClearFreeMemory(ImGuiInputTextState* self);
    void ImGuiInputTextState_ClearSelection(ImGuiInputTextState* self);
    void ImGuiInputTextState_ClearText(ImGuiInputTextState* self);
    void ImGuiInputTextState_CursorAnimReset(ImGuiInputTextState* self);
    void ImGuiInputTextState_CursorClamp(ImGuiInputTextState* self);
    int ImGuiInputTextState_GetCursorPos(ImGuiInputTextState* self);
    int ImGuiInputTextState_GetSelectionEnd(ImGuiInputTextState* self);
    int ImGuiInputTextState_GetSelectionStart(ImGuiInputTextState* self);
    bool ImGuiInputTextState_HasSelection(ImGuiInputTextState* self);
    ImGuiInputTextState* ImGuiInputTextState_ImGuiInputTextState();
    void ImGuiInputTextState_OnCharPressed(ImGuiInputTextState* self, uint c);
    /// Cannot be inline because we call in code in stb_textedit.h implementation
    void ImGuiInputTextState_OnKeyPressed(ImGuiInputTextState* self, int key);
    void ImGuiInputTextState_ReloadUserBufAndKeepSelection(ImGuiInputTextState* self);
    void ImGuiInputTextState_ReloadUserBufAndMoveToEnd(ImGuiInputTextState* self);
    void ImGuiInputTextState_ReloadUserBufAndSelectAll(ImGuiInputTextState* self);
    void ImGuiInputTextState_SelectAll(ImGuiInputTextState* self);
    void ImGuiInputTextState_destroy(ImGuiInputTextState* self);
    ImGuiKeyOwnerData* ImGuiKeyOwnerData_ImGuiKeyOwnerData();
    void ImGuiKeyOwnerData_destroy(ImGuiKeyOwnerData* self);
    ImGuiKeyRoutingData* ImGuiKeyRoutingData_ImGuiKeyRoutingData();
    void ImGuiKeyRoutingData_destroy(ImGuiKeyRoutingData* self);
    void ImGuiKeyRoutingTable_Clear(ImGuiKeyRoutingTable* self);
    ImGuiKeyRoutingTable* ImGuiKeyRoutingTable_ImGuiKeyRoutingTable();
    void ImGuiKeyRoutingTable_destroy(ImGuiKeyRoutingTable* self);
    ImGuiLastItemData* ImGuiLastItemData_ImGuiLastItemData();
    void ImGuiLastItemData_destroy(ImGuiLastItemData* self);
    ImGuiListClipperData* ImGuiListClipperData_ImGuiListClipperData();
    void ImGuiListClipperData_Reset(ImGuiListClipperData* self, ImGuiListClipper* clipper);
    void ImGuiListClipperData_destroy(ImGuiListClipperData* self);
    ImGuiListClipperRange ImGuiListClipperRange_FromIndices(int min, int max);
    ImGuiListClipperRange ImGuiListClipperRange_FromPositions(float y1, float y2, int off_min, int off_max);
    void ImGuiListClipper_Begin(ImGuiListClipper* self, int items_count, float items_height = -1.0f);
    /// Automatically called on the last call of Step() that returns false.
    void ImGuiListClipper_End(ImGuiListClipper* self);
    ImGuiListClipper* ImGuiListClipper_ImGuiListClipper();
    void ImGuiListClipper_IncludeItemByIndex(ImGuiListClipper* self, int item_index);
    /// item_end is exclusive e.g. use (42, 42+1) to make item 42 never clipped.
    void ImGuiListClipper_IncludeItemsByIndex(ImGuiListClipper* self, int item_begin, int item_end);
    void ImGuiListClipper_SeekCursorForItem(ImGuiListClipper* self, int item_index);
    /// Call until it returns false. The DisplayStart/DisplayEnd fields will be set and you can process/draw those items.
    bool ImGuiListClipper_Step(ImGuiListClipper* self);
    void ImGuiListClipper_destroy(ImGuiListClipper* self);
    void ImGuiMenuColumns_CalcNextTotalWidth(ImGuiMenuColumns* self, bool update_offsets);
    float ImGuiMenuColumns_DeclColumns(ImGuiMenuColumns* self, float w_icon, float w_label, float w_shortcut, float w_mark);
    ImGuiMenuColumns* ImGuiMenuColumns_ImGuiMenuColumns();
    void ImGuiMenuColumns_Update(ImGuiMenuColumns* self, float spacing, bool window_reappearing);
    void ImGuiMenuColumns_destroy(ImGuiMenuColumns* self);
    ImGuiMultiSelectState* ImGuiMultiSelectState_ImGuiMultiSelectState();
    void ImGuiMultiSelectState_destroy(ImGuiMultiSelectState* self);
    /// Zero-clear except IO as we preserve IO.Requests[] buffer allocation.
    void ImGuiMultiSelectTempData_Clear(ImGuiMultiSelectTempData* self);
    void ImGuiMultiSelectTempData_ClearIO(ImGuiMultiSelectTempData* self);
    ImGuiMultiSelectTempData* ImGuiMultiSelectTempData_ImGuiMultiSelectTempData();
    void ImGuiMultiSelectTempData_destroy(ImGuiMultiSelectTempData* self);
    void ImGuiNavItemData_Clear(ImGuiNavItemData* self);
    ImGuiNavItemData* ImGuiNavItemData_ImGuiNavItemData();
    void ImGuiNavItemData_destroy(ImGuiNavItemData* self);
    /// Also cleared manually by ItemAdd()!
    void ImGuiNextItemData_ClearFlags(ImGuiNextItemData* self);
    ImGuiNextItemData* ImGuiNextItemData_ImGuiNextItemData();
    void ImGuiNextItemData_destroy(ImGuiNextItemData* self);
    void ImGuiNextWindowData_ClearFlags(ImGuiNextWindowData* self);
    ImGuiNextWindowData* ImGuiNextWindowData_ImGuiNextWindowData();
    void ImGuiNextWindowData_destroy(ImGuiNextWindowData* self);
    ImGuiOldColumnData* ImGuiOldColumnData_ImGuiOldColumnData();
    void ImGuiOldColumnData_destroy(ImGuiOldColumnData* self);
    ImGuiOldColumns* ImGuiOldColumns_ImGuiOldColumns();
    void ImGuiOldColumns_destroy(ImGuiOldColumns* self);
    ImGuiOnceUponAFrame* ImGuiOnceUponAFrame_ImGuiOnceUponAFrame();
    void ImGuiOnceUponAFrame_destroy(ImGuiOnceUponAFrame* self);
    void ImGuiPayload_Clear(ImGuiPayload* self);
    ImGuiPayload* ImGuiPayload_ImGuiPayload();
    bool ImGuiPayload_IsDataType(ImGuiPayload* self, const(char)* type);
    bool ImGuiPayload_IsDelivery(ImGuiPayload* self);
    bool ImGuiPayload_IsPreview(ImGuiPayload* self);
    void ImGuiPayload_destroy(ImGuiPayload* self);
    ImGuiPlatformIO* ImGuiPlatformIO_ImGuiPlatformIO();
    void ImGuiPlatformIO_destroy(ImGuiPlatformIO* self);
    ImGuiPlatformImeData* ImGuiPlatformImeData_ImGuiPlatformImeData();
    void ImGuiPlatformImeData_destroy(ImGuiPlatformImeData* self);
    ImGuiPlatformMonitor* ImGuiPlatformMonitor_ImGuiPlatformMonitor();
    void ImGuiPlatformMonitor_destroy(ImGuiPlatformMonitor* self);
    ImGuiPopupData* ImGuiPopupData_ImGuiPopupData();
    void ImGuiPopupData_destroy(ImGuiPopupData* self);
    ImGuiPtrOrIndex* ImGuiPtrOrIndex_ImGuiPtrOrIndex_Ptr(void* ptr);
    ImGuiPtrOrIndex* ImGuiPtrOrIndex_ImGuiPtrOrIndex_Int(int index);
    void ImGuiPtrOrIndex_destroy(ImGuiPtrOrIndex* self);
    /// Apply selection requests coming from BeginMultiSelect() and EndMultiSelect() functions. It uses 'items_count' passed to BeginMultiSelect()
    void ImGuiSelectionBasicStorage_ApplyRequests(ImGuiSelectionBasicStorage* self, ImGuiMultiSelectIO* ms_io);
    /// Clear selection
    void ImGuiSelectionBasicStorage_Clear(ImGuiSelectionBasicStorage* self);
    /// Query if an item id is in selection.
    bool ImGuiSelectionBasicStorage_Contains(ImGuiSelectionBasicStorage* self, ImGuiID id);
    /// Iterate selection with 'void* it = NULL; ImGuiID id; while (selection.GetNextSelectedItem(&it, &id))  ... '
    bool ImGuiSelectionBasicStorage_GetNextSelectedItem(ImGuiSelectionBasicStorage* self, void** opaque_it, ImGuiID* out_id);
    /// Convert index to item id based on provided adapter.
    ImGuiID ImGuiSelectionBasicStorage_GetStorageIdFromIndex(ImGuiSelectionBasicStorage* self, int idx);
    ImGuiSelectionBasicStorage* ImGuiSelectionBasicStorage_ImGuiSelectionBasicStorage();
    /// Add/remove an item from selection (generally done by ApplyRequests() function)
    void ImGuiSelectionBasicStorage_SetItemSelected(ImGuiSelectionBasicStorage* self, ImGuiID id, bool selected);
    /// Swap two selections
    void ImGuiSelectionBasicStorage_Swap(ImGuiSelectionBasicStorage* self, ImGuiSelectionBasicStorage* r);
    void ImGuiSelectionBasicStorage_destroy(ImGuiSelectionBasicStorage* self);
    /// Apply selection requests by using AdapterSetItemSelected() calls
    void ImGuiSelectionExternalStorage_ApplyRequests(ImGuiSelectionExternalStorage* self, ImGuiMultiSelectIO* ms_io);
    ImGuiSelectionExternalStorage* ImGuiSelectionExternalStorage_ImGuiSelectionExternalStorage();
    void ImGuiSelectionExternalStorage_destroy(ImGuiSelectionExternalStorage* self);
    ImGuiSettingsHandler* ImGuiSettingsHandler_ImGuiSettingsHandler();
    void ImGuiSettingsHandler_destroy(ImGuiSettingsHandler* self);
    ImGuiStackLevelInfo* ImGuiStackLevelInfo_ImGuiStackLevelInfo();
    void ImGuiStackLevelInfo_destroy(ImGuiStackLevelInfo* self);
    ImGuiStoragePair* ImGuiStoragePair_ImGuiStoragePair_Int(ImGuiID _key, int _val);
    ImGuiStoragePair* ImGuiStoragePair_ImGuiStoragePair_Float(ImGuiID _key, float _val);
    ImGuiStoragePair* ImGuiStoragePair_ImGuiStoragePair_Ptr(ImGuiID _key, void* _val);
    void ImGuiStoragePair_destroy(ImGuiStoragePair* self);
    void ImGuiStorage_BuildSortByKey(ImGuiStorage* self);
    void ImGuiStorage_Clear(ImGuiStorage* self);
    bool ImGuiStorage_GetBool(ImGuiStorage* self, ImGuiID key, bool default_val = false);
    bool* ImGuiStorage_GetBoolRef(ImGuiStorage* self, ImGuiID key, bool default_val = false);
    float ImGuiStorage_GetFloat(ImGuiStorage* self, ImGuiID key, float default_val = 0.0f);
    float* ImGuiStorage_GetFloatRef(ImGuiStorage* self, ImGuiID key, float default_val = 0.0f);
    int ImGuiStorage_GetInt(ImGuiStorage* self, ImGuiID key, int default_val = 0);
    int* ImGuiStorage_GetIntRef(ImGuiStorage* self, ImGuiID key, int default_val = 0);
    /// default_val is NULL
    void* ImGuiStorage_GetVoidPtr(ImGuiStorage* self, ImGuiID key);
    void** ImGuiStorage_GetVoidPtrRef(ImGuiStorage* self, ImGuiID key, void* default_val = null);
    void ImGuiStorage_SetAllInt(ImGuiStorage* self, int val);
    void ImGuiStorage_SetBool(ImGuiStorage* self, ImGuiID key, bool val);
    void ImGuiStorage_SetFloat(ImGuiStorage* self, ImGuiID key, float val);
    void ImGuiStorage_SetInt(ImGuiStorage* self, ImGuiID key, int val);
    void ImGuiStorage_SetVoidPtr(ImGuiStorage* self, ImGuiID key, void* val);
    ImGuiStyleMod* ImGuiStyleMod_ImGuiStyleMod_Int(ImGuiStyleVar idx, int v);
    ImGuiStyleMod* ImGuiStyleMod_ImGuiStyleMod_Float(ImGuiStyleVar idx, float v);
    ImGuiStyleMod* ImGuiStyleMod_ImGuiStyleMod_Vec2(ImGuiStyleVar idx, ImVec2 v);
    void ImGuiStyleMod_destroy(ImGuiStyleMod* self);
    void* ImGuiStyleVarInfo_GetVarPtr(ImGuiStyleVarInfo* self, void* parent);
    ImGuiStyle* ImGuiStyle_ImGuiStyle();
    /// Scale all spacing/padding/thickness values. Do not scale fonts.
    void ImGuiStyle_ScaleAllSizes(ImGuiStyle* self, float scale_factor);
    void ImGuiStyle_destroy(ImGuiStyle* self);
    ImGuiTabBar* ImGuiTabBar_ImGuiTabBar();
    void ImGuiTabBar_destroy(ImGuiTabBar* self);
    ImGuiTabItem* ImGuiTabItem_ImGuiTabItem();
    void ImGuiTabItem_destroy(ImGuiTabItem* self);
    ImGuiTableColumnSettings* ImGuiTableColumnSettings_ImGuiTableColumnSettings();
    void ImGuiTableColumnSettings_destroy(ImGuiTableColumnSettings* self);
    ImGuiTableColumnSortSpecs* ImGuiTableColumnSortSpecs_ImGuiTableColumnSortSpecs();
    void ImGuiTableColumnSortSpecs_destroy(ImGuiTableColumnSortSpecs* self);
    ImGuiTableColumn* ImGuiTableColumn_ImGuiTableColumn();
    void ImGuiTableColumn_destroy(ImGuiTableColumn* self);
    ImGuiTableInstanceData* ImGuiTableInstanceData_ImGuiTableInstanceData();
    void ImGuiTableInstanceData_destroy(ImGuiTableInstanceData* self);
    ImGuiTableColumnSettings* ImGuiTableSettings_GetColumnSettings(ImGuiTableSettings* self);
    ImGuiTableSettings* ImGuiTableSettings_ImGuiTableSettings();
    void ImGuiTableSettings_destroy(ImGuiTableSettings* self);
    ImGuiTableSortSpecs* ImGuiTableSortSpecs_ImGuiTableSortSpecs();
    void ImGuiTableSortSpecs_destroy(ImGuiTableSortSpecs* self);
    ImGuiTableTempData* ImGuiTableTempData_ImGuiTableTempData();
    void ImGuiTableTempData_destroy(ImGuiTableTempData* self);
    ImGuiTable* ImGuiTable_ImGuiTable();
    void ImGuiTable_destroy(ImGuiTable* self);
    ImGuiTextBuffer* ImGuiTextBuffer_ImGuiTextBuffer();
    void ImGuiTextBuffer_append(ImGuiTextBuffer* self, const(char)* str, const(char)* str_end = null);
    void ImGuiTextBuffer_appendf(ImGuiTextBuffer* self,  const char* fmt, ...);
    void ImGuiTextBuffer_appendfv(ImGuiTextBuffer* self, const(char)* fmt, va_list args);
    const(char)* ImGuiTextBuffer_begin(ImGuiTextBuffer* self);
    const(char)* ImGuiTextBuffer_c_str(ImGuiTextBuffer* self);
    void ImGuiTextBuffer_clear(ImGuiTextBuffer* self);
    void ImGuiTextBuffer_destroy(ImGuiTextBuffer* self);
    bool ImGuiTextBuffer_empty(ImGuiTextBuffer* self);
    /// Buf is zero-terminated, so end() will point on the zero-terminator
    const(char)* ImGuiTextBuffer_end(ImGuiTextBuffer* self);
    void ImGuiTextBuffer_reserve(ImGuiTextBuffer* self, int capacity);
    /// Similar to resize(0) on ImVector: empty string but don't free buffer.
    void ImGuiTextBuffer_resize(ImGuiTextBuffer* self, int size);
    int ImGuiTextBuffer_size(ImGuiTextBuffer* self);
    void ImGuiTextFilter_Build(ImGuiTextFilter* self);
    void ImGuiTextFilter_Clear(ImGuiTextFilter* self);
    /// Helper calling InputText+Build
    bool ImGuiTextFilter_Draw(ImGuiTextFilter* self, const(char)* label = "Filter(inc,-exc)", float width = 0.0f);
    ImGuiTextFilter* ImGuiTextFilter_ImGuiTextFilter(const(char)* default_filter = "");
    bool ImGuiTextFilter_IsActive(ImGuiTextFilter* self);
    bool ImGuiTextFilter_PassFilter(ImGuiTextFilter* self, const(char)* text, const(char)* text_end = null);
    void ImGuiTextFilter_destroy(ImGuiTextFilter* self);
    void ImGuiTextIndex_append(ImGuiTextIndex* self, const(char)* base, int old_size, int new_size);
    void ImGuiTextIndex_clear(ImGuiTextIndex* self);
    const(char)* ImGuiTextIndex_get_line_begin(ImGuiTextIndex* self, const(char)* base, int n);
    const(char)* ImGuiTextIndex_get_line_end(ImGuiTextIndex* self, const(char)* base, int n);
    int ImGuiTextIndex_size(ImGuiTextIndex* self);
    ImGuiTextRange* ImGuiTextRange_ImGuiTextRange_Nil();
    ImGuiTextRange* ImGuiTextRange_ImGuiTextRange_Str(const(char)* _b, const(char)* _e);
    void ImGuiTextRange_destroy(ImGuiTextRange* self);
    bool ImGuiTextRange_empty(ImGuiTextRange* self);
    void ImGuiTextRange_split(ImGuiTextRange* self, char separator, ImVector!(ImGuiTextRange)* outItem);
    /// We preserve remaining data for easier debugging
    void ImGuiTypingSelectState_Clear(ImGuiTypingSelectState* self);
    ImGuiTypingSelectState* ImGuiTypingSelectState_ImGuiTypingSelectState();
    void ImGuiTypingSelectState_destroy(ImGuiTypingSelectState* self);
    void ImGuiViewportP_CalcWorkRectPos(ImVec2* pOut, ImGuiViewportP* self, const ImVec2 inset_min);
    void ImGuiViewportP_CalcWorkRectSize(ImVec2* pOut, ImGuiViewportP* self, const ImVec2 inset_min, const ImVec2 inset_max);
    void ImGuiViewportP_ClearRequestFlags(ImGuiViewportP* self);
    void ImGuiViewportP_GetBuildWorkRect(ImRect* pOut, ImGuiViewportP* self);
    void ImGuiViewportP_GetMainRect(ImRect* pOut, ImGuiViewportP* self);
    void ImGuiViewportP_GetWorkRect(ImRect* pOut, ImGuiViewportP* self);
    ImGuiViewportP* ImGuiViewportP_ImGuiViewportP();
    /// Update public fields
    void ImGuiViewportP_UpdateWorkRect(ImGuiViewportP* self);
    void ImGuiViewportP_destroy(ImGuiViewportP* self);
    void ImGuiViewport_GetCenter(ImVec2* pOut, ImGuiViewport* self);
    void ImGuiViewport_GetWorkCenter(ImVec2* pOut, ImGuiViewport* self);
    ImGuiViewport* ImGuiViewport_ImGuiViewport();
    void ImGuiViewport_destroy(ImGuiViewport* self);
    ImGuiWindowClass* ImGuiWindowClass_ImGuiWindowClass();
    void ImGuiWindowClass_destroy(ImGuiWindowClass* self);
    char* ImGuiWindowSettings_GetName(ImGuiWindowSettings* self);
    ImGuiWindowSettings* ImGuiWindowSettings_ImGuiWindowSettings();
    void ImGuiWindowSettings_destroy(ImGuiWindowSettings* self);
    ImGuiID ImGuiWindow_GetID_Str(ImGuiWindow* self, const(char)* str, const(char)* str_end = null);
    ImGuiID ImGuiWindow_GetID_Ptr(ImGuiWindow* self, const void* ptr);
    ImGuiID ImGuiWindow_GetID_Int(ImGuiWindow* self, int n);
    ImGuiID ImGuiWindow_GetIDFromPos(ImGuiWindow* self, const ImVec2 p_abs);
    ImGuiID ImGuiWindow_GetIDFromRectangle(ImGuiWindow* self, const ImRect r_abs);
    ImGuiWindow* ImGuiWindow_ImGuiWindow(ImGuiContext* context, const(char)* name);
    void ImGuiWindow_MenuBarRect(ImRect* pOut, ImGuiWindow* self);
    void ImGuiWindow_Rect(ImRect* pOut, ImGuiWindow* self);
    void ImGuiWindow_TitleBarRect(ImRect* pOut, ImGuiWindow* self);
    void ImGuiWindow_destroy(ImGuiWindow* self);
    void ImRect_Add_Vec2(ImRect* self, const ImVec2 p);
    void ImRect_Add_Rect(ImRect* self, const ImRect r);
    /// Simple version, may lead to an inverted rectangle, which is fine for Contains/Overlaps test but not for display.
    void ImRect_ClipWith(ImRect* self, const ImRect r);
    /// Full version, ensure both points are fully clipped.
    void ImRect_ClipWithFull(ImRect* self, const ImRect r);
    bool ImRect_Contains_Vec2(ImRect* self, const ImVec2 p);
    bool ImRect_Contains_Rect(ImRect* self, const ImRect r);
    bool ImRect_ContainsWithPad(ImRect* self, const ImVec2 p, const ImVec2 pad);
    void ImRect_Expand_Float(ImRect* self, const float amount);
    void ImRect_Expand_Vec2(ImRect* self, const ImVec2 amount);
    void ImRect_Floor(ImRect* self);
    float ImRect_GetArea(ImRect* self);
    /// Bottom-left
    void ImRect_GetBL(ImVec2* pOut, ImRect* self);
    /// Bottom-right
    void ImRect_GetBR(ImVec2* pOut, ImRect* self);
    void ImRect_GetCenter(ImVec2* pOut, ImRect* self);
    float ImRect_GetHeight(ImRect* self);
    void ImRect_GetSize(ImVec2* pOut, ImRect* self);
    /// Top-left
    void ImRect_GetTL(ImVec2* pOut, ImRect* self);
    /// Top-right
    void ImRect_GetTR(ImVec2* pOut, ImRect* self);
    float ImRect_GetWidth(ImRect* self);
    ImRect* ImRect_ImRect_Nil();
    ImRect* ImRect_ImRect_Vec2(const ImVec2 min, const ImVec2 max);
    ImRect* ImRect_ImRect_Vec4(const ImVec4 v);
    ImRect* ImRect_ImRect_Float(float x1, float y1, float x2, float y2);
    bool ImRect_IsInverted(ImRect* self);
    bool ImRect_Overlaps(ImRect* self, const ImRect r);
    void ImRect_ToVec4(ImVec4* pOut, ImRect* self);
    void ImRect_Translate(ImRect* self, const ImVec2 d);
    void ImRect_TranslateX(ImRect* self, float dx);
    void ImRect_TranslateY(ImRect* self, float dy);
    void ImRect_destroy(ImRect* self);
    void ImTextureData_Create(ImTextureData* self, ImTextureFormat format, int w, int h);
    void ImTextureData_DestroyPixels(ImTextureData* self);
    int ImTextureData_GetPitch(ImTextureData* self);
    char* ImTextureData_GetPixels(ImTextureData* self);
    char* ImTextureData_GetPixelsAt(ImTextureData* self, int x, int y);
    int ImTextureData_GetSizeInBytes(ImTextureData* self);
    ImTextureID ImTextureData_GetTexID(ImTextureData* self);
    void ImTextureData_GetTexRef(ImTextureRef* pOut, ImTextureData* self);
    ImTextureData* ImTextureData_ImTextureData();
    /// Call after honoring a request. Never modify Status directly!
    void ImTextureData_SetStatus(ImTextureData* self, ImTextureStatus status);
    /// Call after creating or destroying the texture. Never modify TexID directly!
    void ImTextureData_SetTexID(ImTextureData* self, ImTextureID tex_id);
    void ImTextureData_destroy(ImTextureData* self);
    /// == (_TexData ? _TexData->TexID : _TexID) /// Implemented below in the file.
    ImTextureID ImTextureRef_GetTexID(ImTextureRef* self);
    ImTextureRef* ImTextureRef_ImTextureRef_Nil();
    ImTextureRef* ImTextureRef_ImTextureRef_TextureID(ImTextureID tex_id);
    void ImTextureRef_destroy(ImTextureRef* self);
    ImVec1* ImVec1_ImVec1_Nil();
    ImVec1* ImVec1_ImVec1_Float(float _x);
    void ImVec1_destroy(ImVec1* self);
    ImVec2* ImVec2_ImVec2_Nil();
    ImVec2* ImVec2_ImVec2_Float(float _x, float _y);
    void ImVec2_destroy(ImVec2* self);
    ImVec2i* ImVec2i_ImVec2i_Nil();
    ImVec2i* ImVec2i_ImVec2i_Int(int _x, int _y);
    void ImVec2i_destroy(ImVec2i* self);
    ImVec2ih* ImVec2ih_ImVec2ih_Nil();
    ImVec2ih* ImVec2ih_ImVec2ih_short(short _x, short _y);
    ImVec2ih* ImVec2ih_ImVec2ih_Vec2(const ImVec2 rhs);
    void ImVec2ih_destroy(ImVec2ih* self);
    ImVec4* ImVec4_ImVec4_Nil();
    ImVec4* ImVec4_ImVec4_Float(float _x, float _y, float _z, float _w);
    void ImVec4_destroy(ImVec4* self);
    /// accept contents of a given type. If ImGuiDragDropFlags_AcceptBeforeDelivery is set you can peek into the payload before the mouse button is released.
    const(ImGuiPayload)* igAcceptDragDropPayload(const(char)* type, ImGuiDragDropFlags flags = ImGuiDragDropFlags.None);
    /// Activate an item by ID (button, checkbox, tree node etc.). Activation is queued and processed on the next frame when the item is encountered again.
    void igActivateItemByID(ImGuiID id);
    ImGuiID igAddContextHook(ImGuiContext* context, const ImGuiContextHook* hook);
    void igAddDrawListToDrawDataEx(ImDrawData* draw_data, ImVector!(ImDrawList*)* out_list, ImDrawList* draw_list);
    void igAddSettingsHandler(const ImGuiSettingsHandler* handler);
    /// vertically align upcoming text baseline to FramePadding.y so that it will align properly to regularly framed items (call if you have text on a line before a framed item)
    void igAlignTextToFramePadding();
    /// square button with an arrow shape
    bool igArrowButton(const(char)* str_id, ImGuiDir dir);
    bool igArrowButtonEx(const(char)* str_id, ImGuiDir dir, ImVec2 size_arg, ImGuiButtonFlags flags = ImGuiButtonFlags.None);
    bool igBegin(const(char)* name, bool* p_open = null, ImGuiWindowFlags flags = ImGuiWindowFlags.None);
    bool igBeginBoxSelect(const ImRect scope_rect, ImGuiWindow* window, ImGuiID box_select_id, ImGuiMultiSelectFlags ms_flags);
    bool igBeginChild_Str(const(char)* str_id, const ImVec2 size = ImVec2(0,0), ImGuiChildFlags child_flags = ImGuiChildFlags.None, ImGuiWindowFlags window_flags = ImGuiWindowFlags.None);
    bool igBeginChild_ID(ImGuiID id, const ImVec2 size = ImVec2(0,0), ImGuiChildFlags child_flags = ImGuiChildFlags.None, ImGuiWindowFlags window_flags = ImGuiWindowFlags.None);
    bool igBeginChildEx(const(char)* name, ImGuiID id, const ImVec2 size_arg, ImGuiChildFlags child_flags, ImGuiWindowFlags window_flags);
    /// setup number of columns. use an identifier to distinguish multiple column sets. close with EndColumns().
    void igBeginColumns(const(char)* str_id, int count, ImGuiOldColumnFlags flags = ImGuiOldColumnFlags.None);
    bool igBeginCombo(const(char)* label, const(char)* preview_value, ImGuiComboFlags flags = ImGuiComboFlags.None);
    bool igBeginComboPopup(ImGuiID popup_id, const ImRect bb, ImGuiComboFlags flags);
    bool igBeginComboPreview();
    void igBeginDisabled(bool disabled = true);
    void igBeginDisabledOverrideReenable();
    void igBeginDockableDragDropSource(ImGuiWindow* window);
    void igBeginDockableDragDropTarget(ImGuiWindow* window);
    void igBeginDocked(ImGuiWindow* window, bool* p_open);
    /// call after submitting an item which may be dragged. when this return true, you can call SetDragDropPayload() + EndDragDropSource()
    bool igBeginDragDropSource(ImGuiDragDropFlags flags = ImGuiDragDropFlags.None);
    /// call after submitting an item that may receive a payload. If this returns true, you can call AcceptDragDropPayload() + EndDragDropTarget()
    bool igBeginDragDropTarget();
    bool igBeginDragDropTargetCustom(const ImRect bb, ImGuiID id);
    bool igBeginErrorTooltip();
    /// lock horizontal starting position
    void igBeginGroup();
    /// begin/append a tooltip window if preceding item was hovered.
    bool igBeginItemTooltip();
    /// open a framed scrolling region
    bool igBeginListBox(const(char)* label, const ImVec2 size = ImVec2(0,0));
    /// create and append to a full screen menu-bar.
    bool igBeginMainMenuBar();
    /// create a sub-menu entry. only call EndMenu() if this returns true!
    bool igBeginMenu(const(char)* label, bool enabled = true);
    /// append to menu-bar of current window (requires ImGuiWindowFlags_MenuBar flag set on parent window).
    bool igBeginMenuBar();
    bool igBeginMenuEx(const(char)* label, const(char)* icon, bool enabled = true);
    ImGuiMultiSelectIO* igBeginMultiSelect(ImGuiMultiSelectFlags flags, int selection_size = -1, int items_count = -1);
    /// return true if the popup is open, and you can start outputting to it.
    bool igBeginPopup(const(char)* str_id, ImGuiWindowFlags flags = ImGuiWindowFlags.None);
    /// open+begin popup when clicked on last item. Use str_id==NULL to associate the popup to previous item. If you want to use that on a non-interactive item such as Text() you need to pass in an explicit ID here. read comments in .cpp!
    bool igBeginPopupContextItem(const(char)* str_id = null, ImGuiPopupFlags popup_flags = ImGuiPopupFlags.MouseButtonDefault_);
    /// open+begin popup when clicked in void (where there are no windows).
    bool igBeginPopupContextVoid(const(char)* str_id = null, ImGuiPopupFlags popup_flags = ImGuiPopupFlags.MouseButtonDefault_);
    /// open+begin popup when clicked on current window.
    bool igBeginPopupContextWindow(const(char)* str_id = null, ImGuiPopupFlags popup_flags = ImGuiPopupFlags.MouseButtonDefault_);
    bool igBeginPopupEx(ImGuiID id, ImGuiWindowFlags extra_window_flags);
    bool igBeginPopupMenuEx(ImGuiID id, const(char)* label, ImGuiWindowFlags extra_window_flags);
    /// return true if the modal is open, and you can start outputting to it.
    bool igBeginPopupModal(const(char)* name, bool* p_open = null, ImGuiWindowFlags flags = ImGuiWindowFlags.None);
    /// create and append into a TabBar
    bool igBeginTabBar(const(char)* str_id, ImGuiTabBarFlags flags = ImGuiTabBarFlags.None);
    bool igBeginTabBarEx(ImGuiTabBar* tab_bar, const ImRect bb, ImGuiTabBarFlags flags);
    /// create a Tab. Returns true if the Tab is selected.
    bool igBeginTabItem(const(char)* label, bool* p_open = null, ImGuiTabItemFlags flags = ImGuiTabItemFlags.None);
    bool igBeginTable(const(char)* str_id, int columns, ImGuiTableFlags flags = ImGuiTableFlags.None, const ImVec2 outer_size = ImVec2(0.0f,0.0f), float inner_width = 0.0f);
    bool igBeginTableEx(const(char)* name, ImGuiID id, int columns_count, ImGuiTableFlags flags = ImGuiTableFlags.None, const ImVec2 outer_size = ImVec2(0,0), float inner_width = 0.0f);
    /// begin/append a tooltip window.
    bool igBeginTooltip();
    bool igBeginTooltipEx(ImGuiTooltipFlags tooltip_flags, ImGuiWindowFlags extra_window_flags);
    bool igBeginTooltipHidden();
    bool igBeginViewportSideBar(const(char)* name, ImGuiViewport* viewport, ImGuiDir dir, float size, ImGuiWindowFlags window_flags);
    void igBringWindowToDisplayBack(ImGuiWindow* window);
    void igBringWindowToDisplayBehind(ImGuiWindow* window, ImGuiWindow* above_window);
    void igBringWindowToDisplayFront(ImGuiWindow* window);
    void igBringWindowToFocusFront(ImGuiWindow* window);
    /// draw a small circle + keep the cursor on the same line. advance cursor x position by GetTreeNodeToLabelSpacing(), same distance that TreeNode() uses
    void igBullet();
    /// shortcut for Bullet()+Text()
    void igBulletText(const(char)* fmt, ...);
    void igBulletTextV(const(char)* fmt, va_list args);
    /// button
    bool igButton(const(char)* label, const ImVec2 size = ImVec2(0,0));
    bool igButtonBehavior(const ImRect bb, ImGuiID id, bool* out_hovered, bool* out_held, ImGuiButtonFlags flags = ImGuiButtonFlags.None);
    bool igButtonEx(const(char)* label, const ImVec2 size_arg = ImVec2(0,0), ImGuiButtonFlags flags = ImGuiButtonFlags.None);
    void igCalcItemSize(ImVec2* pOut, ImVec2 size, float default_w, float default_h);
    /// width of item given pushed settings and current cursor position. NOT necessarily the width of last item unlike most 'Item' functions.
    float igCalcItemWidth();
    ImDrawFlags igCalcRoundingFlagsForRectInRect(const ImRect r_in, const ImRect r_outer, float threshold);
    void igCalcTextSize(ImVec2* pOut, const(char)* text, const(char)* text_end = null, bool hide_text_after_double_hash = false, float wrap_width = -1.0f);
    int igCalcTypematicRepeatAmount(float t0, float t1, float repeat_delay, float repeat_rate);
    void igCalcWindowNextAutoFitSize(ImVec2* pOut, ImGuiWindow* window);
    float igCalcWrapWidthForPos(const ImVec2 pos, float wrap_pos_x);
    void igCallContextHooks(ImGuiContext* context, ImGuiContextHookType type);
    bool igCheckbox(const(char)* label, bool* v);
    bool igCheckboxFlags_IntPtr(const(char)* label, int* flags, int flags_value);
    bool igCheckboxFlags_UintPtr(const(char)* label, uint* flags, uint flags_value);
    bool igCheckboxFlags_S64Ptr(const(char)* label, ImS64* flags, ImS64 flags_value);
    bool igCheckboxFlags_U64Ptr(const(char)* label, ImU64* flags, ImU64 flags_value);
    void igClearActiveID();
    void igClearDragDrop();
    void igClearIniSettings();
    void igClearWindowSettings(const(char)* name);
    bool igCloseButton(ImGuiID id, const ImVec2 pos);
    /// manually close the popup we have begin-ed into.
    void igCloseCurrentPopup();
    void igClosePopupToLevel(int remaining, bool restore_focus_to_window_under_popup);
    void igClosePopupsExceptModals();
    void igClosePopupsOverWindow(ImGuiWindow* ref_window, bool restore_focus_to_window_under_popup);
    bool igCollapseButton(ImGuiID id, const ImVec2 pos, ImGuiDockNode* dock_node);
    /// if returning 'true' the header is open. doesn't indent nor push on ID stack. user doesn't have to call TreePop().
    bool igCollapsingHeader_TreeNodeFlags(const(char)* label, ImGuiTreeNodeFlags flags = ImGuiTreeNodeFlags.None);
    /// when 'p_visible != NULL': if '*p_visible==true' display an additional small close button on upper right of the header which will set the bool to false when clicked, if '*p_visible==false' don't display the header.
    bool igCollapsingHeader_BoolPtr(const(char)* label, bool* p_visible, ImGuiTreeNodeFlags flags = ImGuiTreeNodeFlags.None);
    /// display a color square/button, hover for details, return true when pressed.
    bool igColorButton(const(char)* desc_id, const ImVec4 col, ImGuiColorEditFlags flags = ImGuiColorEditFlags.None, const ImVec2 size = ImVec2(0,0));
    ImU32 igColorConvertFloat4ToU32(const ImVec4 inItem);
    void igColorConvertHSVtoRGB(float h, float s, float v, float* out_r, float* out_g, float* out_b);
    void igColorConvertRGBtoHSV(float r, float g, float b, float* out_h, float* out_s, float* out_v);
    void igColorConvertU32ToFloat4(ImVec4* pOut, ImU32 inItem);
    bool igColorEdit3(const(char)* label, float[3]*/*[3]*/ col, ImGuiColorEditFlags flags = ImGuiColorEditFlags.None);
    bool igColorEdit4(const(char)* label, float[4]*/*[4]*/ col, ImGuiColorEditFlags flags = ImGuiColorEditFlags.None);
    void igColorEditOptionsPopup(const float* col, ImGuiColorEditFlags flags);
    bool igColorPicker3(const(char)* label, float[3]*/*[3]*/ col, ImGuiColorEditFlags flags = ImGuiColorEditFlags.None);
    bool igColorPicker4(const(char)* label, float[4]*/*[4]*/ col, ImGuiColorEditFlags flags = ImGuiColorEditFlags.None, const float* ref_col = null);
    void igColorPickerOptionsPopup(const float* ref_col, ImGuiColorEditFlags flags);
    void igColorTooltip(const(char)* text, const float* col, ImGuiColorEditFlags flags);
    void igColumns(int count = 1, const(char)* id = null, bool borders = true);
    bool igCombo_Str_arr(const(char)* label, int* current_item, const(char)** items, int items_count, int popup_max_height_in_items = -1);
    /// Separate items with \0 within a string, end item-list with \0\0. e.g. "One\0Two\0Three\0"
    bool igCombo_Str(const(char)* label, int* current_item, const(char)* items_separated_by_zeros, int popup_max_height_in_items = -1);
    bool igCombo_FnStrPtr(const(char)* label, int* current_item, const(char)* function(void* user_data,int idx) getter, void* user_data, int items_count, int popup_max_height_in_items = -1);
    ImGuiKey igConvertSingleModFlagToKey(ImGuiKey key);
    ImGuiContext* igCreateContext(ImFontAtlas* shared_font_atlas = null);
    ImGuiWindowSettings* igCreateNewWindowSettings(const(char)* name);
    bool igDataTypeApplyFromText(const(char)* buf, ImGuiDataType data_type, void* p_data, const(char)* format, void* p_data_when_empty = null);
    void igDataTypeApplyOp(ImGuiDataType data_type, int op, void* output, const void* arg_1, const void* arg_2);
    bool igDataTypeClamp(ImGuiDataType data_type, void* p_data, const void* p_min, const void* p_max);
    int igDataTypeCompare(ImGuiDataType data_type, const void* arg_1, const void* arg_2);
    int igDataTypeFormatString(char* buf, int buf_size, ImGuiDataType data_type, const void* p_data, const(char)* format);
    const(ImGuiDataTypeInfo)* igDataTypeGetInfo(ImGuiDataType data_type);
    bool igDataTypeIsZero(ImGuiDataType data_type, const void* p_data);
    /// size >= 0 : alloc, size = -1 : free
    void igDebugAllocHook(ImGuiDebugAllocInfo* info, int frame_count, void* ptr, size_t size);
    bool igDebugBreakButton(const(char)* label, const(char)* description_of_location);
    void igDebugBreakButtonTooltip(bool keyboard_only, const(char)* description_of_location);
    void igDebugBreakClearData();
    /// This is called by IMGUI_CHECKVERSION() macro.
    bool igDebugCheckVersionAndDataLayout(const(char)* version_str, size_t sz_io, size_t sz_style, size_t sz_vec2, size_t sz_vec4, size_t sz_drawvert, size_t sz_drawidx);
    void igDebugDrawCursorPos(ImU32 col = 4278190335);
    void igDebugDrawItemRect(ImU32 col = 4278190335);
    void igDebugDrawLineExtents(ImU32 col = 4278190335);
    void igDebugFlashStyleColor(ImGuiCol idx);
    void igDebugHookIdInfo(ImGuiID id, ImGuiDataType data_type, const void* data_id, const void* data_id_end);
    /// Call sparingly: only 1 at the same time!
    void igDebugLocateItem(ImGuiID target_id);
    /// Only call on reaction to a mouse Hover: because only 1 at the same time!
    void igDebugLocateItemOnHover(ImGuiID target_id);
    void igDebugLocateItemResolveWithLastItem();
    /// Call via IMGUI_DEBUG_LOG() for maximum stripping in caller code!
    void igDebugLog(const(char)* fmt, ...);
    void igDebugLogV(const(char)* fmt, va_list args);
    void igDebugNodeColumns(ImGuiOldColumns* columns);
    void igDebugNodeDockNode(ImGuiDockNode* node, const(char)* label);
    void igDebugNodeDrawCmdShowMeshAndBoundingBox(ImDrawList* out_draw_list, const ImDrawList* draw_list, const ImDrawCmd* draw_cmd, bool show_mesh, bool show_aabb);
    void igDebugNodeDrawList(ImGuiWindow* window, ImGuiViewportP* viewport, const ImDrawList* draw_list, const(char)* label);
    void igDebugNodeFont(ImFont* font);
    void igDebugNodeFontGlyph(ImFont* font, const(ImFontGlyph)* glyph);
    void igDebugNodeFontGlyphesForSrcMask(ImFont* font, ImFontBaked* baked, int src_mask);
    void igDebugNodeInputTextState(ImGuiInputTextState* state);
    void igDebugNodeMultiSelectState(ImGuiMultiSelectState* state);
    void igDebugNodePlatformMonitor(ImGuiPlatformMonitor* monitor, const(char)* label, int idx);
    void igDebugNodeStorage(ImGuiStorage* storage, const(char)* label);
    void igDebugNodeTabBar(ImGuiTabBar* tab_bar, const(char)* label);
    void igDebugNodeTable(ImGuiTable* table);
    void igDebugNodeTableSettings(ImGuiTableSettings* settings);
    /// ID used to facilitate persisting the "current" texture.
    void igDebugNodeTexture(ImTextureData* tex, int int_id, const ImFontAtlasRect* highlight_rect = null);
    void igDebugNodeTypingSelectState(ImGuiTypingSelectState* state);
    void igDebugNodeViewport(ImGuiViewportP* viewport);
    void igDebugNodeWindow(ImGuiWindow* window, const(char)* label);
    void igDebugNodeWindowSettings(ImGuiWindowSettings* settings);
    void igDebugNodeWindowsList(ImVector!(ImGuiWindow*)* windows, const(char)* label);
    void igDebugNodeWindowsListByBeginStackParent(ImGuiWindow** windows, int windows_size, ImGuiWindow* parent_in_begin_stack);
    void igDebugRenderKeyboardPreview(ImDrawList* draw_list);
    void igDebugRenderViewportThumbnail(ImDrawList* draw_list, ImGuiViewportP* viewport, const ImRect bb);
    void igDebugStartItemPicker();
    void igDebugTextEncoding(const(char)* text);
    void igDebugTextUnformattedWithLocateItem(const(char)* line_begin, const(char)* line_end);
    /// NULL = destroy current context
    void igDestroyContext(ImGuiContext* ctx = null);
    void igDestroyPlatformWindow(ImGuiViewportP* viewport);
    /// call DestroyWindow platform functions for all viewports. call from backend Shutdown() if you need to close platform windows before imgui shutdown. otherwise will be called by DestroyContext().
    void igDestroyPlatformWindows();
    ImGuiID igDockBuilderAddNode(ImGuiID node_id = 0, ImGuiDockNodeFlags flags = ImGuiDockNodeFlags.None);
    void igDockBuilderCopyDockSpace(ImGuiID src_dockspace_id, ImGuiID dst_dockspace_id, ImVector!(const(char)*)* in_window_remap_pairs);
    void igDockBuilderCopyNode(ImGuiID src_node_id, ImGuiID dst_node_id, ImVector!(ImGuiID)* out_node_remap_pairs);
    void igDockBuilderCopyWindowSettings(const(char)* src_name, const(char)* dst_name);
    void igDockBuilderDockWindow(const(char)* window_name, ImGuiID node_id);
    void igDockBuilderFinish(ImGuiID node_id);
    ImGuiDockNode* igDockBuilderGetCentralNode(ImGuiID node_id);
    ImGuiDockNode* igDockBuilderGetNode(ImGuiID node_id);
    /// Remove node and all its child, undock all windows
    void igDockBuilderRemoveNode(ImGuiID node_id);
    /// Remove all split/hierarchy. All remaining docked windows will be re-docked to the remaining root node (node_id).
    void igDockBuilderRemoveNodeChildNodes(ImGuiID node_id);
    void igDockBuilderRemoveNodeDockedWindows(ImGuiID node_id, bool clear_settings_refs = true);
    void igDockBuilderSetNodePos(ImGuiID node_id, ImVec2 pos);
    void igDockBuilderSetNodeSize(ImGuiID node_id, ImVec2 size);
    /// Create 2 child nodes in this parent node.
    ImGuiID igDockBuilderSplitNode(ImGuiID node_id, ImGuiDir split_dir, float size_ratio_for_node_at_dir, ImGuiID* out_id_at_dir, ImGuiID* out_id_at_opposite_dir);
    bool igDockContextCalcDropPosForDocking(ImGuiWindow* target, ImGuiDockNode* target_node, ImGuiWindow* payload_window, ImGuiDockNode* payload_node, ImGuiDir split_dir, bool split_outer, ImVec2* out_pos);
    /// Use root_id==0 to clear all
    void igDockContextClearNodes(ImGuiContext* ctx, ImGuiID root_id, bool clear_settings_refs);
    void igDockContextEndFrame(ImGuiContext* ctx);
    ImGuiDockNode* igDockContextFindNodeByID(ImGuiContext* ctx, ImGuiID id);
    ImGuiID igDockContextGenNodeID(ImGuiContext* ctx);
    void igDockContextInitialize(ImGuiContext* ctx);
    void igDockContextNewFrameUpdateDocking(ImGuiContext* ctx);
    void igDockContextNewFrameUpdateUndocking(ImGuiContext* ctx);
    void igDockContextProcessUndockNode(ImGuiContext* ctx, ImGuiDockNode* node);
    void igDockContextProcessUndockWindow(ImGuiContext* ctx, ImGuiWindow* window, bool clear_persistent_docking_ref = true);
    void igDockContextQueueDock(ImGuiContext* ctx, ImGuiWindow* target, ImGuiDockNode* target_node, ImGuiWindow* payload, ImGuiDir split_dir, float split_ratio, bool split_outer);
    void igDockContextQueueUndockNode(ImGuiContext* ctx, ImGuiDockNode* node);
    void igDockContextQueueUndockWindow(ImGuiContext* ctx, ImGuiWindow* window);
    void igDockContextRebuildNodes(ImGuiContext* ctx);
    void igDockContextShutdown(ImGuiContext* ctx);
    bool igDockNodeBeginAmendTabBar(ImGuiDockNode* node);
    void igDockNodeEndAmendTabBar();
    int igDockNodeGetDepth(const ImGuiDockNode* node);
    ImGuiDockNode* igDockNodeGetRootNode(ImGuiDockNode* node);
    ImGuiID igDockNodeGetWindowMenuButtonId(const ImGuiDockNode* node);
    bool igDockNodeIsInHierarchyOf(ImGuiDockNode* node, ImGuiDockNode* parent);
    void igDockNodeWindowMenuHandler_Default(ImGuiContext* ctx, ImGuiDockNode* node, ImGuiTabBar* tab_bar);
    ImGuiID igDockSpace(ImGuiID dockspace_id, const ImVec2 size = ImVec2(0,0), ImGuiDockNodeFlags flags = ImGuiDockNodeFlags.None, const ImGuiWindowClass* window_class = null);
    ImGuiID igDockSpaceOverViewport(ImGuiID dockspace_id = 0, const ImGuiViewport* viewport = null, ImGuiDockNodeFlags flags = ImGuiDockNodeFlags.None, const ImGuiWindowClass* window_class = null);
    bool igDragBehavior(ImGuiID id, ImGuiDataType data_type, void* p_v, float v_speed, const void* p_min, const void* p_max, const(char)* format, ImGuiSliderFlags flags);
    /// If v_min >= v_max we have no bound
    bool igDragFloat(const(char)* label, float* v, float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, const(char)* format = "%.3f", ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    bool igDragFloat2(const(char)* label, float[2]*/*[2]*/ v, float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, const(char)* format = "%.3f", ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    bool igDragFloat3(const(char)* label, float[3]*/*[3]*/ v, float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, const(char)* format = "%.3f", ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    bool igDragFloat4(const(char)* label, float[4]*/*[4]*/ v, float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, const(char)* format = "%.3f", ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    bool igDragFloatRange2(const(char)* label, float* v_current_min, float* v_current_max, float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, const(char)* format = "%.3f", const(char)* format_max = null, ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    /// If v_min >= v_max we have no bound
    bool igDragInt(const(char)* label, int* v, float v_speed = 1.0f, int v_min = 0, int v_max = 0, const(char)* format = "%d", ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    bool igDragInt2(const(char)* label, int[2]*/*[2]*/ v, float v_speed = 1.0f, int v_min = 0, int v_max = 0, const(char)* format = "%d", ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    bool igDragInt3(const(char)* label, int[3]*/*[3]*/ v, float v_speed = 1.0f, int v_min = 0, int v_max = 0, const(char)* format = "%d", ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    bool igDragInt4(const(char)* label, int[4]*/*[4]*/ v, float v_speed = 1.0f, int v_min = 0, int v_max = 0, const(char)* format = "%d", ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    bool igDragIntRange2(const(char)* label, int* v_current_min, int* v_current_max, float v_speed = 1.0f, int v_min = 0, int v_max = 0, const(char)* format = "%d", const(char)* format_max = null, ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    bool igDragScalar(const(char)* label, ImGuiDataType data_type, void* p_data, float v_speed = 1.0f, const void* p_min = null, const void* p_max = null, const(char)* format = null, ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    bool igDragScalarN(const(char)* label, ImGuiDataType data_type, void* p_data, int components, float v_speed = 1.0f, const void* p_min = null, const void* p_max = null, const(char)* format = null, ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    /// add a dummy item of given size. unlike InvisibleButton(), Dummy() won't take the mouse click or be navigable into.
    void igDummy(const ImVec2 size);
    void igEnd();
    void igEndBoxSelect(const ImRect scope_rect, ImGuiMultiSelectFlags ms_flags);
    void igEndChild();
    /// close columns
    void igEndColumns();
    /// only call EndCombo() if BeginCombo() returns true!
    void igEndCombo();
    void igEndComboPreview();
    void igEndDisabled();
    void igEndDisabledOverrideReenable();
    /// only call EndDragDropSource() if BeginDragDropSource() returns true!
    void igEndDragDropSource();
    /// only call EndDragDropTarget() if BeginDragDropTarget() returns true!
    void igEndDragDropTarget();
    void igEndErrorTooltip();
    /// ends the Dear ImGui frame. automatically called by Render(). If you don't need to render data (skipping rendering) you may call EndFrame() without Render()... but you'll have wasted CPU already! If you don't need to render, better to not create any windows and not call NewFrame() at all!
    void igEndFrame();
    /// unlock horizontal starting position + capture the whole group bounding box into one "item" (so you can use IsItemHovered() or layout primitives such as SameLine() on whole group, etc.)
    void igEndGroup();
    /// only call EndListBox() if BeginListBox() returned true!
    void igEndListBox();
    /// only call EndMainMenuBar() if BeginMainMenuBar() returns true!
    void igEndMainMenuBar();
    /// only call EndMenu() if BeginMenu() returns true!
    void igEndMenu();
    /// only call EndMenuBar() if BeginMenuBar() returns true!
    void igEndMenuBar();
    ImGuiMultiSelectIO* igEndMultiSelect();
    /// only call EndPopup() if BeginPopupXXX() returns true!
    void igEndPopup();
    /// only call EndTabBar() if BeginTabBar() returns true!
    void igEndTabBar();
    /// only call EndTabItem() if BeginTabItem() returns true!
    void igEndTabItem();
    /// only call EndTable() if BeginTable() returns true!
    void igEndTable();
    /// only call EndTooltip() if BeginTooltip()/BeginItemTooltip() returns true!
    void igEndTooltip();
    void igErrorCheckEndFrameFinalizeErrorTooltip();
    void igErrorCheckUsingSetCursorPosToExtendParentBoundaries();
    bool igErrorLog(const(char)* msg);
    void igErrorRecoveryStoreState(ImGuiErrorRecoveryState* state_out);
    void igErrorRecoveryTryToRecoverState(const ImGuiErrorRecoveryState* state_in);
    void igErrorRecoveryTryToRecoverWindowState(const ImGuiErrorRecoveryState* state_in);
    void igFindBestWindowPosForPopup(ImVec2* pOut, ImGuiWindow* window);
    void igFindBestWindowPosForPopupEx(ImVec2* pOut, const ImVec2 ref_pos, const ImVec2 size, ImGuiDir* last_dir, const ImRect r_outer, const ImRect r_avoid, ImGuiPopupPositionPolicy policy);
    ImGuiWindow* igFindBlockingModal(ImGuiWindow* window);
    ImGuiWindow* igFindBottomMostVisibleWindowWithinBeginStack(ImGuiWindow* window);
    ImGuiViewportP* igFindHoveredViewportFromPlatformWindowStack(const ImVec2 mouse_platform_pos);
    void igFindHoveredWindowEx(const ImVec2 pos, bool find_first_and_in_any_viewport, ImGuiWindow** out_hovered_window, ImGuiWindow** out_hovered_window_under_moving_window);
    ImGuiOldColumns* igFindOrCreateColumns(ImGuiWindow* window, ImGuiID id);
    /// Find the optional ## from which we stop displaying text.
    const(char)* igFindRenderedTextEnd(const(char)* text, const(char)* text_end = null);
    ImGuiSettingsHandler* igFindSettingsHandler(const(char)* type_name);
    /// this is a helper for backends.
    ImGuiViewport* igFindViewportByID(ImGuiID id);
    /// this is a helper for backends. the type platform_handle is decided by the backend (e.g. HWND, MyWindow*, GLFWwindow* etc.)
    ImGuiViewport* igFindViewportByPlatformHandle(void* platform_handle);
    ImGuiWindow* igFindWindowByID(ImGuiID id);
    ImGuiWindow* igFindWindowByName(const(char)* name);
    int igFindWindowDisplayIndex(ImGuiWindow* window);
    ImGuiWindowSettings* igFindWindowSettingsByID(ImGuiID id);
    ImGuiWindowSettings* igFindWindowSettingsByWindow(ImGuiWindow* window);
    ImGuiKeyChord igFixupKeyChord(ImGuiKeyChord key_chord);
    /// Focus last item (no selection/activation).
    void igFocusItem();
    void igFocusTopMostWindowUnderOne(ImGuiWindow* under_this_window, ImGuiWindow* ignore_window, ImGuiViewport* filter_viewport, ImGuiFocusRequestFlags flags);
    void igFocusWindow(ImGuiWindow* window, ImGuiFocusRequestFlags flags = ImGuiFocusRequestFlags.None);
    void igGcAwakeTransientWindowBuffers(ImGuiWindow* window);
    void igGcCompactTransientMiscBuffers();
    void igGcCompactTransientWindowBuffers(ImGuiWindow* window);
    ImGuiID igGetActiveID();
    void igGetAllocatorFunctions(ImGuiMemAllocFunc* p_alloc_func, ImGuiMemFreeFunc* p_free_func, void** p_user_data);
    /// get background draw list for the given viewport or viewport associated to the current window. this draw list will be the first rendering one. Useful to quickly draw shapes/text behind dear imgui contents.
    ImDrawList* igGetBackgroundDrawList(ImGuiViewport* viewport = null);
    ImGuiBoxSelectState* igGetBoxSelectState(ImGuiID id);
    const(char)* igGetClipboardText();
    /// retrieve given style color with style alpha applied and optional extra alpha multiplier, packed as a 32-bit value suitable for ImDrawList
    ImU32 igGetColorU32_Col(ImGuiCol idx, float alpha_mul = 1.0f);
    /// retrieve given color with style alpha applied, packed as a 32-bit value suitable for ImDrawList
    ImU32 igGetColorU32_Vec4(const ImVec4 col);
    /// retrieve given color with style alpha applied, packed as a 32-bit value suitable for ImDrawList
    ImU32 igGetColorU32_U32(ImU32 col, float alpha_mul = 1.0f);
    /// get current column index
    int igGetColumnIndex();
    float igGetColumnNormFromOffset(const ImGuiOldColumns* columns, float offset);
    /// get position of column line (in pixels, from the left side of the contents region). pass -1 to use current column, otherwise 0..GetColumnsCount() inclusive. column 0 is typically 0.0f
    float igGetColumnOffset(int column_index = -1);
    float igGetColumnOffsetFromNorm(const ImGuiOldColumns* columns, float offset_norm);
    /// get column width (in pixels). pass -1 to use current column
    float igGetColumnWidth(int column_index = -1);
    int igGetColumnsCount();
    ImGuiID igGetColumnsID(const(char)* str_id, int count);
    /// available space from current position. THIS IS YOUR BEST FRIEND.
    void igGetContentRegionAvail(ImVec2* pOut);
    ImGuiContext* igGetCurrentContext();
    /// Focus scope we are outputting into, set by PushFocusScope()
    ImGuiID igGetCurrentFocusScope();
    ImGuiTabBar* igGetCurrentTabBar();
    ImGuiTable* igGetCurrentTable();
    ImGuiWindow* igGetCurrentWindow();
    ImGuiWindow* igGetCurrentWindowRead();
    /// [window-local] cursor position in window-local coordinates. This is not your best friend.
    void igGetCursorPos(ImVec2* pOut);
    /// [window-local] "
    float igGetCursorPosX();
    /// [window-local] "
    float igGetCursorPosY();
    /// cursor position, absolute coordinates. THIS IS YOUR BEST FRIEND (prefer using this rather than GetCursorPos(), also more useful to work with ImDrawList API).
    void igGetCursorScreenPos(ImVec2* pOut);
    /// [window-local] initial cursor position, in window-local coordinates. Call GetCursorScreenPos() after Begin() to get the absolute coordinates version.
    void igGetCursorStartPos(ImVec2* pOut);
    ImFont* igGetDefaultFont();
    /// peek directly into the current payload from anywhere. returns NULL when drag and drop is finished or inactive. use ImGuiPayload::IsDataType() to test for the payload type.
    const(ImGuiPayload)* igGetDragDropPayload();
    /// valid after Render() and until the next call to NewFrame(). Call ImGui_ImplXXXX_RenderDrawData() function in your Renderer Backend to render.
    ImDrawData* igGetDrawData();
    /// you may use this when creating your own ImDrawList instances.
    ImDrawListSharedData* igGetDrawListSharedData();
    ImGuiID igGetFocusID();
    /// get current font
    ImFont* igGetFont();
    /// get current font bound at current size /// == GetFont()->GetFontBaked(GetFontSize())
    ImFontBaked* igGetFontBaked();
    float igGetFontRasterizerDensity();
    /// get current font size (= height in pixels) of current font with external scale factors applied. Use ImGui::GetStyle().FontSizeBase to get value before external scale factors.
    float igGetFontSize();
    /// get UV coordinate for a white pixel, useful to draw custom shapes via the ImDrawList API
    void igGetFontTexUvWhitePixel(ImVec2* pOut);
    /// get foreground draw list for the given viewport or viewport associated to the current window. this draw list will be the top-most rendered one. Useful to quickly draw shapes/text over dear imgui contents.
    ImDrawList* igGetForegroundDrawList_ViewportPtr(ImGuiViewport* viewport = null);
    ImDrawList* igGetForegroundDrawList_WindowPtr(ImGuiWindow* window);
    /// get global imgui frame count. incremented by 1 every frame.
    int igGetFrameCount();
    /// ~ FontSize + style.FramePadding.y * 2
    float igGetFrameHeight();
    /// ~ FontSize + style.FramePadding.y * 2 + style.ItemSpacing.y (distance in pixels between 2 consecutive lines of framed widgets)
    float igGetFrameHeightWithSpacing();
    ImGuiID igGetHoveredID();
    /// calculate unique ID (hash of whole ID stack + given parameter). e.g. if you want to query into ImGuiStorage yourself
    ImGuiID igGetID_Str(const(char)* str_id);
    ImGuiID igGetID_StrStr(const(char)* str_id_begin, const(char)* str_id_end);
    ImGuiID igGetID_Ptr(const void* ptr_id);
    ImGuiID igGetID_Int(int int_id);
    ImGuiID igGetIDWithSeed_Str(const(char)* str_id_begin, const(char)* str_id_end, ImGuiID seed);
    ImGuiID igGetIDWithSeed_Int(int n, ImGuiID seed);
    /// access the ImGuiIO structure (mouse/keyboard/gamepad inputs, time, various configuration options/flags)
    ImGuiIO* igGetIO_Nil();
    ImGuiIO* igGetIO_ContextPtr(ImGuiContext* ctx);
    /// Get input text state if active
    ImGuiInputTextState* igGetInputTextState(ImGuiID id);
    ImGuiItemFlags igGetItemFlags();
    /// get ID of last item (~~ often same ImGui::GetID(label) beforehand)
    ImGuiID igGetItemID();
    /// get lower-right bounding rectangle of the last item (screen space)
    void igGetItemRectMax(ImVec2* pOut);
    /// get upper-left bounding rectangle of the last item (screen space)
    void igGetItemRectMin(ImVec2* pOut);
    /// get size of last item
    void igGetItemRectSize(ImVec2* pOut);
    ImGuiItemStatusFlags igGetItemStatusFlags();
    const(char)* igGetKeyChordName(ImGuiKeyChord key_chord);
    ImGuiKeyData* igGetKeyData_ContextPtr(ImGuiContext* ctx, ImGuiKey key);
    ImGuiKeyData* igGetKeyData_Key(ImGuiKey key);
    void igGetKeyMagnitude2d(ImVec2* pOut, ImGuiKey key_left, ImGuiKey key_right, ImGuiKey key_up, ImGuiKey key_down);
    /// [DEBUG] returns English name of the key. Those names are provided for debugging purpose and are not meant to be saved persistently nor compared.
    const(char)* igGetKeyName(ImGuiKey key);
    ImGuiID igGetKeyOwner(ImGuiKey key);
    ImGuiKeyOwnerData* igGetKeyOwnerData(ImGuiContext* ctx, ImGuiKey key);
    /// uses provided repeat rate/delay. return a count, most often 0 or 1 but might be >1 if RepeatRate is small enough that DeltaTime > RepeatRate
    int igGetKeyPressedAmount(ImGuiKey key, float repeat_delay, float rate);
    /// return primary/default viewport. This can never be NULL.
    ImGuiViewport* igGetMainViewport();
    /// return the number of successive mouse-clicks at the time where a click happen (otherwise 0).
    int igGetMouseClickedCount(ImGuiMouseButton button);
    /// get desired mouse cursor shape. Important: reset in ImGui::NewFrame(), this is updated during the frame. valid before Render(). If you use software rendering by setting io.MouseDrawCursor ImGui will render those for you
    ImGuiMouseCursor igGetMouseCursor();
    /// return the delta from the initial clicking position while the mouse button is pressed or was just released. This is locked and return 0.0f until the mouse moves past a distance threshold at least once (uses io.MouseDraggingThreshold if lock_threshold < 0.0f)
    void igGetMouseDragDelta(ImVec2* pOut, ImGuiMouseButton button = ImGuiMouseButton.Left, float lock_threshold = -1.0f);
    /// shortcut to ImGui::GetIO().MousePos provided by user, to be consistent with other calls
    void igGetMousePos(ImVec2* pOut);
    /// retrieve mouse position at the time of opening popup we have BeginPopup() into (helper to avoid user backing that value themselves)
    void igGetMousePosOnOpeningCurrentPopup(ImVec2* pOut);
    ImGuiMultiSelectState* igGetMultiSelectState(ImGuiID id);
    float igGetNavTweakPressedAmount(ImGuiAxis axis);
    /// access the ImGuiPlatformIO structure (mostly hooks/functions to connect to platform/renderer and OS Clipboard, IME etc.)
    ImGuiPlatformIO* igGetPlatformIO_Nil();
    ImGuiPlatformIO* igGetPlatformIO_ContextPtr(ImGuiContext* ctx);
    void igGetPopupAllowedExtentRect(ImRect* pOut, ImGuiWindow* window);
    float igGetRoundedFontSize(float size);
    /// get maximum scrolling amount ~~ ContentSize.x - WindowSize.x - DecorationsSize.x
    float igGetScrollMaxX();
    /// get maximum scrolling amount ~~ ContentSize.y - WindowSize.y - DecorationsSize.y
    float igGetScrollMaxY();
    /// get scrolling amount [0 .. GetScrollMaxX()]
    float igGetScrollX();
    /// get scrolling amount [0 .. GetScrollMaxY()]
    float igGetScrollY();
    ImGuiKeyRoutingData* igGetShortcutRoutingData(ImGuiKeyChord key_chord);
    ImGuiStorage* igGetStateStorage();
    /// access the Style structure (colors, sizes). Always use PushStyleColor(), PushStyleVar() to modify style mid-frame!
    ImGuiStyle* igGetStyle();
    /// get a string corresponding to the enum value (for display, saving, etc.).
    const(char)* igGetStyleColorName(ImGuiCol idx);
    /// retrieve style color as stored in ImGuiStyle structure. use to feed back into PushStyleColor(), otherwise use GetColorU32() to get style color with style alpha baked in.
    const(ImVec4)* igGetStyleColorVec4(ImGuiCol idx);
    const(ImGuiStyleVarInfo)* igGetStyleVarInfo(ImGuiStyleVar idx);
    /// ~ FontSize
    float igGetTextLineHeight();
    /// ~ FontSize + style.ItemSpacing.y (distance in pixels between 2 consecutive lines of text)
    float igGetTextLineHeightWithSpacing();
    /// get global imgui time. incremented by io.DeltaTime every frame.
    double igGetTime();
    ImGuiWindow* igGetTopMostAndVisiblePopupModal();
    ImGuiWindow* igGetTopMostPopupModal();
    /// horizontal distance preceding label when using TreeNode*() or Bullet() == (g.FontSize + style.FramePadding.x*2) for a regular unframed TreeNode
    float igGetTreeNodeToLabelSpacing();
    void igGetTypematicRepeatRate(ImGuiInputFlags flags, float* repeat_delay, float* repeat_rate);
    ImGuiTypingSelectRequest* igGetTypingSelectRequest(ImGuiTypingSelectFlags flags = ImGuiTypingSelectFlags.None);
    /// get the compiled version string e.g. "1.80 WIP" (essentially the value for IMGUI_VERSION from the compiled version of imgui.cpp)
    const(char)* igGetVersion();
    const(ImGuiPlatformMonitor)* igGetViewportPlatformMonitor(ImGuiViewport* viewport);
    bool igGetWindowAlwaysWantOwnTabBar(ImGuiWindow* window);
    ImGuiID igGetWindowDockID();
    ImGuiDockNode* igGetWindowDockNode();
    /// get DPI scale currently associated to the current window's viewport.
    float igGetWindowDpiScale();
    /// get draw list associated to the current window, to append your own drawing primitives
    ImDrawList* igGetWindowDrawList();
    /// get current window height (IT IS UNLIKELY YOU EVER NEED TO USE THIS). Shortcut for GetWindowSize().y.
    float igGetWindowHeight();
    /// get current window position in screen space (IT IS UNLIKELY YOU EVER NEED TO USE THIS. Consider always using GetCursorScreenPos() and GetContentRegionAvail() instead)
    void igGetWindowPos(ImVec2* pOut);
    ImGuiID igGetWindowResizeBorderID(ImGuiWindow* window, ImGuiDir dir);
    /// 0..3: corners
    ImGuiID igGetWindowResizeCornerID(ImGuiWindow* window, int n);
    ImGuiID igGetWindowScrollbarID(ImGuiWindow* window, ImGuiAxis axis);
    void igGetWindowScrollbarRect(ImRect* pOut, ImGuiWindow* window, ImGuiAxis axis);
    /// get current window size (IT IS UNLIKELY YOU EVER NEED TO USE THIS. Consider always using GetCursorScreenPos() and GetContentRegionAvail() instead)
    void igGetWindowSize(ImVec2* pOut);
    /// get viewport currently associated to the current window.
    ImGuiViewport* igGetWindowViewport();
    /// get current window width (IT IS UNLIKELY YOU EVER NEED TO USE THIS). Shortcut for GetWindowSize().x.
    float igGetWindowWidth();
    int igImAbs_Int(int x);
    float igImAbs_Float(float x);
    double igImAbs_double(double x);
    ImU32 igImAlphaBlendColors(ImU32 col_a, ImU32 col_b);
    void igImBezierCubicCalc(ImVec2* pOut, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, float t);
    /// For curves with explicit number of segments
    void igImBezierCubicClosestPoint(ImVec2* pOut, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, const ImVec2 p, int num_segments);
    /// For auto-tessellated curves you can use tess_tol = style.CurveTessellationTol
    void igImBezierCubicClosestPointCasteljau(ImVec2* pOut, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, const ImVec2 p4, const ImVec2 p, float tess_tol);
    void igImBezierQuadraticCalc(ImVec2* pOut, const ImVec2 p1, const ImVec2 p2, const ImVec2 p3, float t);
    void igImBitArrayClearAllBits(ImU32* arr, int bitcount);
    void igImBitArrayClearBit(ImU32* arr, int n);
    size_t igImBitArrayGetStorageSizeInBytes(int bitcount);
    void igImBitArraySetBit(ImU32* arr, int n);
    void igImBitArraySetBitRange(ImU32* arr, int n, int n2);
    bool igImBitArrayTestBit(const ImU32* arr, int n);
    bool igImCharIsBlankA(char c);
    bool igImCharIsBlankW(uint c);
    bool igImCharIsXdigitA(char c);
    void igImClamp(ImVec2* pOut, const ImVec2 v, const ImVec2 mn, const ImVec2 mx);
    uint igImCountSetBits(uint v);
    float igImDot(const ImVec2 a, const ImVec2 b);
    float igImExponentialMovingAverage(float avg, float sample, int n);
    bool igImFileClose(ImFileHandle file);
    ImU64 igImFileGetSize(ImFileHandle file);
    void* igImFileLoadToMemory(const(char)* filename, const(char)* mode, size_t* out_file_size = null, int padding_bytes = 0);
    ImFileHandle igImFileOpen(const(char)* filename, const(char)* mode);
    ImU64 igImFileRead(void* data, ImU64 size, ImU64 count, ImFileHandle file);
    ImU64 igImFileWrite(const void* data, ImU64 size, ImU64 count, ImFileHandle file);
    /// Decent replacement for floorf()
    float igImFloor_Float(float f);
    void igImFloor_Vec2(ImVec2* pOut, const ImVec2 v);
    void igImFontAtlasAddDrawListSharedData(ImFontAtlas* atlas, ImDrawListSharedData* data);
    ImFontBaked* igImFontAtlasBakedAdd(ImFontAtlas* atlas, ImFont* font, float font_size, float font_rasterizer_density, ImGuiID baked_id);
    ImFontGlyph* igImFontAtlasBakedAddFontGlyph(ImFontAtlas* atlas, ImFontBaked* baked, ImFontConfig* src, const(ImFontGlyph)* in_glyph);
    void igImFontAtlasBakedDiscard(ImFontAtlas* atlas, ImFont* font, ImFontBaked* baked);
    void igImFontAtlasBakedDiscardFontGlyph(ImFontAtlas* atlas, ImFont* font, ImFontBaked* baked, ImFontGlyph* glyph);
    ImFontBaked* igImFontAtlasBakedGetClosestMatch(ImFontAtlas* atlas, ImFont* font, float font_size, float font_rasterizer_density);
    ImGuiID igImFontAtlasBakedGetId(ImGuiID font_id, float baked_size, float rasterizer_density);
    ImFontBaked* igImFontAtlasBakedGetOrAdd(ImFontAtlas* atlas, ImFont* font, float font_size, float font_rasterizer_density);
    void igImFontAtlasBakedSetFontGlyphBitmap(ImFontAtlas* atlas, ImFontBaked* baked, ImFontConfig* src, ImFontGlyph* glyph, ImTextureRect* r, const(char)* src_pixels, ImTextureFormat src_fmt, int src_pitch);
    /// Clear output and custom rects
    void igImFontAtlasBuildClear(ImFontAtlas* atlas);
    void igImFontAtlasBuildDestroy(ImFontAtlas* atlas);
    void igImFontAtlasBuildDiscardBakes(ImFontAtlas* atlas, int unused_frames);
    void igImFontAtlasBuildGetOversampleFactors(ImFontConfig* src, ImFontBaked* baked, int* out_oversample_h, int* out_oversample_v);
    void igImFontAtlasBuildInit(ImFontAtlas* atlas);
    /// Legacy
    void igImFontAtlasBuildLegacyPreloadAllGlyphRanges(ImFontAtlas* atlas);
    void igImFontAtlasBuildMain(ImFontAtlas* atlas);
    void igImFontAtlasBuildRenderBitmapFromString(ImFontAtlas* atlas, int x, int y, int w, int h, const(char)* in_str, char in_marker_char);
    void igImFontAtlasBuildSetupFontLoader(ImFontAtlas* atlas, const(ImFontLoader)* font_loader);
    void igImFontAtlasBuildSetupFontSpecialGlyphs(ImFontAtlas* atlas, ImFont* font, ImFontConfig* src);
    void igImFontAtlasBuildUpdatePointers(ImFontAtlas* atlas);
    void igImFontAtlasDebugLogTextureRequests(ImFontAtlas* atlas);
    void igImFontAtlasFontDestroyOutput(ImFontAtlas* atlas, ImFont* font);
    void igImFontAtlasFontDestroySourceData(ImFontAtlas* atlas, ImFontConfig* src);
    void igImFontAtlasFontDiscardBakes(ImFontAtlas* atlas, ImFont* font, int unused_frames);
    /// Using FontDestroyOutput/FontInitOutput sequence useful notably if font loader params have changed
    bool igImFontAtlasFontInitOutput(ImFontAtlas* atlas, ImFont* font);
    void igImFontAtlasFontSourceAddToFont(ImFontAtlas* atlas, ImFont* font, ImFontConfig* src);
    bool igImFontAtlasFontSourceInit(ImFontAtlas* atlas, ImFontConfig* src);
    const(ImFontLoader)* igImFontAtlasGetFontLoaderForStbTruetype();
    bool igImFontAtlasGetMouseCursorTexData(ImFontAtlas* atlas, ImGuiMouseCursor cursor_type, ImVec2* out_offset, ImVec2* out_size, ImVec2[2]*/*[2]*/ out_uv_border, ImVec2[2]*/*[2]*/ out_uv_fill);
    ImFontAtlasRectId igImFontAtlasPackAddRect(ImFontAtlas* atlas, int w, int h, ImFontAtlasRectEntry* overwrite_entry = null);
    void igImFontAtlasPackDiscardRect(ImFontAtlas* atlas, ImFontAtlasRectId id);
    ImTextureRect* igImFontAtlasPackGetRect(ImFontAtlas* atlas, ImFontAtlasRectId id);
    ImTextureRect* igImFontAtlasPackGetRectSafe(ImFontAtlas* atlas, ImFontAtlasRectId id);
    void igImFontAtlasPackInit(ImFontAtlas* atlas);
    int igImFontAtlasRectId_GetGeneration(ImFontAtlasRectId id);
    int igImFontAtlasRectId_GetIndex(ImFontAtlasRectId id);
    ImFontAtlasRectId igImFontAtlasRectId_Make(int index_idx, int gen_idx);
    void igImFontAtlasRemoveDrawListSharedData(ImFontAtlas* atlas, ImDrawListSharedData* data);
    ImTextureData* igImFontAtlasTextureAdd(ImFontAtlas* atlas, int w, int h);
    void igImFontAtlasTextureBlockConvert(const(char)* src_pixels, ImTextureFormat src_fmt, int src_pitch, char* dst_pixels, ImTextureFormat dst_fmt, int dst_pitch, int w, int h);
    void igImFontAtlasTextureBlockCopy(ImTextureData* src_tex, int src_x, int src_y, ImTextureData* dst_tex, int dst_x, int dst_y, int w, int h);
    void igImFontAtlasTextureBlockFill(ImTextureData* dst_tex, int dst_x, int dst_y, int w, int h, ImU32 col);
    void igImFontAtlasTextureBlockPostProcess(ImFontAtlasPostProcessData* data);
    void igImFontAtlasTextureBlockPostProcessMultiply(ImFontAtlasPostProcessData* data, float multiply_factor);
    void igImFontAtlasTextureBlockQueueUpload(ImFontAtlas* atlas, ImTextureData* tex, int x, int y, int w, int h);
    void igImFontAtlasTextureCompact(ImFontAtlas* atlas);
    void igImFontAtlasTextureGetSizeEstimate(ImVec2i* pOut, ImFontAtlas* atlas);
    void igImFontAtlasTextureGrow(ImFontAtlas* atlas, int old_w = -1, int old_h = -1);
    void igImFontAtlasTextureMakeSpace(ImFontAtlas* atlas);
    void igImFontAtlasTextureRepack(ImFontAtlas* atlas, int w, int h);
    void igImFontAtlasUpdateDrawListsSharedData(ImFontAtlas* atlas);
    void igImFontAtlasUpdateDrawListsTextures(ImFontAtlas* atlas, ImTextureRef old_tex, ImTextureRef new_tex);
    void igImFontAtlasUpdateNewFrame(ImFontAtlas* atlas, int frame_count, bool renderer_has_textures);
    int igImFormatString(char* buf, size_t buf_size, const(char)* fmt, ...);
    void igImFormatStringToTempBuffer(const char** out_buf, const char** out_buf_end, const(char)* fmt, ...);
    void igImFormatStringToTempBufferV(const char** out_buf, const char** out_buf_end, const(char)* fmt, va_list args);
    int igImFormatStringV(char* buf, size_t buf_size, const(char)* fmt, va_list args);
    ImGuiID igImHashData(const void* data, size_t data_size, ImGuiID seed = 0);
    ImGuiID igImHashStr(const(char)* data, size_t data_size = 0, ImGuiID seed = 0);
    float igImInvLength(const ImVec2 lhs, float fail_value);
    bool igImIsFloatAboveGuaranteedIntegerPrecision(float f);
    bool igImIsPowerOfTwo_Int(int v);
    bool igImIsPowerOfTwo_U64(ImU64 v);
    float igImLengthSqr_Vec2(const ImVec2 lhs);
    float igImLengthSqr_Vec4(const ImVec4 lhs);
    void igImLerp_Vec2Float(ImVec2* pOut, const ImVec2 a, const ImVec2 b, float t);
    void igImLerp_Vec2Vec2(ImVec2* pOut, const ImVec2 a, const ImVec2 b, const ImVec2 t);
    void igImLerp_Vec4(ImVec4* pOut, const ImVec4 a, const ImVec4 b, float t);
    void igImLineClosestPoint(ImVec2* pOut, const ImVec2 a, const ImVec2 b, const ImVec2 p);
    float igImLinearRemapClamp(float s0, float s1, float d0, float d1, float x);
    float igImLinearSweep(float current, float target, float speed);
    /// DragBehaviorT/SliderBehaviorT uses ImLog with either float/double and need the precision
    float igImLog_Float(float x);
    double igImLog_double(double x);
    ImGuiStoragePair* igImLowerBound(ImGuiStoragePair* in_begin, ImGuiStoragePair* in_end, ImGuiID key);
    void igImMax(ImVec2* pOut, const ImVec2 lhs, const ImVec2 rhs);
    /// Duplicate a chunk of memory.
    void* igImMemdup(const void* src, size_t size);
    void igImMin(ImVec2* pOut, const ImVec2 lhs, const ImVec2 rhs);
    int igImModPositive(int a, int b);
    void igImMul(ImVec2* pOut, const ImVec2 lhs, const ImVec2 rhs);
    const(char)* igImParseFormatFindEnd(const(char)* format);
    const(char)* igImParseFormatFindStart(const(char)* format);
    int igImParseFormatPrecision(const(char)* format, int default_value);
    void igImParseFormatSanitizeForPrinting(const(char)* fmt_in, char* fmt_out, size_t fmt_out_size);
    const(char)* igImParseFormatSanitizeForScanning(const(char)* fmt_in, char* fmt_out, size_t fmt_out_size);
    const(char)* igImParseFormatTrimDecorations(const(char)* format, char* buf, size_t buf_size);
    /// DragBehaviorT/SliderBehaviorT uses ImPow with either float/double and need the precision
    float igImPow_Float(float x, float y);
    double igImPow_double(double x, double y);
    void igImQsort(void* base, size_t count, size_t size_of_element, int function(const(void*), const(void*)) compare_func);
    void igImRotate(ImVec2* pOut, const ImVec2 v, float cos_a, float sin_a);
    float igImRound64(float f);
    float igImRsqrt_Float(float x);
    double igImRsqrt_double(double x);
    float igImSaturate(float f);
    /// Sign operator - returns -1, 0 or 1 based on sign of argument
    float igImSign_Float(float x);
    double igImSign_double(double x);
    /// Find first non-blank character.
    const(char)* igImStrSkipBlank(const(char)* str);
    /// Remove leading and trailing blanks from a buffer.
    void igImStrTrimBlanks(char* str);
    /// Find beginning-of-line
    const(char)* igImStrbol(const(char)* buf_mid_line, const(char)* buf_begin);
    /// Find first occurrence of 'c' in string range.
    const(char)* igImStrchrRange(const(char)* str_begin, const(char)* str_end, char c);
    /// Duplicate a string.
    char* igImStrdup(const(char)* str);
    /// Copy in provided buffer, recreate buffer if needed.
    char* igImStrdupcpy(char* dst, size_t* p_dst_size, const(char)* str);
    /// End end-of-line
    const(char)* igImStreolRange(const(char)* str, const(char)* str_end);
    /// Case insensitive compare.
    int igImStricmp(const(char)* str1, const(char)* str2);
    /// Find a substring in a string range.
    const(char)* igImStristr(const(char)* haystack, const(char)* haystack_end, const(char)* needle, const(char)* needle_end);
    /// Computer string length (ImWchar string)
    int igImStrlenW(const(ImWchar)* str);
    /// Copy to a certain count and always zero terminate (strncpy doesn't).
    void igImStrncpy(char* dst, const(char)* src, size_t count);
    /// Case insensitive compare to a certain count.
    int igImStrnicmp(const(char)* str1, const(char)* str2, size_t count);
    /// read one character. return input UTF-8 bytes count
    int igImTextCharFromUtf8(uint* out_char, const(char)* in_text, const(char)* in_text_end);
    /// return out_buf
    const(char)* igImTextCharToUtf8(char[5]*/*[5]*/ out_buf, uint c);
    /// return number of UTF-8 code-points (NOT bytes count)
    int igImTextCountCharsFromUtf8(const(char)* in_text, const(char)* in_text_end);
    /// return number of lines taken by text. trailing carriage return doesn't count as an extra line.
    int igImTextCountLines(const(char)* in_text, const(char)* in_text_end);
    /// return number of bytes to express one char in UTF-8
    int igImTextCountUtf8BytesFromChar(const(char)* in_text, const(char)* in_text_end);
    /// return number of bytes to express string in UTF-8
    int igImTextCountUtf8BytesFromStr(const(ImWchar)* in_text, const(ImWchar)* in_text_end);
    /// return previous UTF-8 code-point.
    const(char)* igImTextFindPreviousUtf8Codepoint(const(char)* in_text_start, const(char)* in_text_curr);
    /// return input UTF-8 bytes count
    int igImTextStrFromUtf8(ImWchar* out_buf, int out_buf_size, const(char)* in_text, const(char)* in_text_end, const char** in_remaining = null);
    /// return output UTF-8 bytes count
    int igImTextStrToUtf8(char* out_buf, int out_buf_size, const(ImWchar)* in_text, const(ImWchar)* in_text_end);
    int igImTextureDataGetFormatBytesPerPixel(ImTextureFormat format);
    const(char)* igImTextureDataGetFormatName(ImTextureFormat format);
    const(char)* igImTextureDataGetStatusName(ImTextureStatus status);
    char igImToUpper(char c);
    float igImTriangleArea(const ImVec2 a, const ImVec2 b, const ImVec2 c);
    void igImTriangleBarycentricCoords(const ImVec2 a, const ImVec2 b, const ImVec2 c, const ImVec2 p, float* out_u, float* out_v, float* out_w);
    void igImTriangleClosestPoint(ImVec2* pOut, const ImVec2 a, const ImVec2 b, const ImVec2 c, const ImVec2 p);
    bool igImTriangleContainsPoint(const ImVec2 a, const ImVec2 b, const ImVec2 c, const ImVec2 p);
    bool igImTriangleIsClockwise(const ImVec2 a, const ImVec2 b, const ImVec2 c);
    float igImTrunc_Float(float f);
    void igImTrunc_Vec2(ImVec2* pOut, const ImVec2 v);
    float igImTrunc64(float f);
    int igImUpperPowerOfTwo(int v);
    void igImage(ImTextureRef tex_ref, const ImVec2 image_size, const ImVec2 uv0 = ImVec2(0,0), const ImVec2 uv1 = ImVec2(1,1));
    bool igImageButton(const(char)* str_id, ImTextureRef tex_ref, const ImVec2 image_size, const ImVec2 uv0 = ImVec2(0,0), const ImVec2 uv1 = ImVec2(1,1), const ImVec4 bg_col = ImVec4(0,0,0,0), const ImVec4 tint_col = ImVec4(1,1,1,1));
    bool igImageButtonEx(ImGuiID id, ImTextureRef tex_ref, const ImVec2 image_size, const ImVec2 uv0, const ImVec2 uv1, const ImVec4 bg_col, const ImVec4 tint_col, ImGuiButtonFlags flags = ImGuiButtonFlags.None);
    void igImageWithBg(ImTextureRef tex_ref, const ImVec2 image_size, const ImVec2 uv0 = ImVec2(0,0), const ImVec2 uv1 = ImVec2(1,1), const ImVec4 bg_col = ImVec4(0,0,0,0), const ImVec4 tint_col = ImVec4(1,1,1,1));
    /// move content position toward the right, by indent_w, or style.IndentSpacing if indent_w <= 0
    void igIndent(float indent_w = 0.0f);
    void igInitialize();
    bool igInputDouble(const(char)* label, double* v, double step = 0.0, double step_fast = 0.0, const(char)* format = "%.6f", ImGuiInputTextFlags flags = ImGuiInputTextFlags.None);
    bool igInputFloat(const(char)* label, float* v, float step = 0.0f, float step_fast = 0.0f, const(char)* format = "%.3f", ImGuiInputTextFlags flags = ImGuiInputTextFlags.None);
    bool igInputFloat2(const(char)* label, float[2]*/*[2]*/ v, const(char)* format = "%.3f", ImGuiInputTextFlags flags = ImGuiInputTextFlags.None);
    bool igInputFloat3(const(char)* label, float[3]*/*[3]*/ v, const(char)* format = "%.3f", ImGuiInputTextFlags flags = ImGuiInputTextFlags.None);
    bool igInputFloat4(const(char)* label, float[4]*/*[4]*/ v, const(char)* format = "%.3f", ImGuiInputTextFlags flags = ImGuiInputTextFlags.None);
    bool igInputInt(const(char)* label, int* v, int step = 1, int step_fast = 100, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None);
    bool igInputInt2(const(char)* label, int[2]*/*[2]*/ v, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None);
    bool igInputInt3(const(char)* label, int[3]*/*[3]*/ v, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None);
    bool igInputInt4(const(char)* label, int[4]*/*[4]*/ v, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None);
    bool igInputScalar(const(char)* label, ImGuiDataType data_type, void* p_data, const void* p_step = null, const void* p_step_fast = null, const(char)* format = null, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None);
    bool igInputScalarN(const(char)* label, ImGuiDataType data_type, void* p_data, int components, const void* p_step = null, const void* p_step_fast = null, const(char)* format = null, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None);
    bool igInputText(const(char)* label, char* buf, size_t buf_size, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None, ImGuiInputTextCallback callback = null, void* user_data = null);
    void igInputTextDeactivateHook(ImGuiID id);
    bool igInputTextEx(const(char)* label, const(char)* hint, char* buf, int buf_size, const ImVec2 size_arg, ImGuiInputTextFlags flags, ImGuiInputTextCallback callback = null, void* user_data = null);
    bool igInputTextMultiline(const(char)* label, char* buf, size_t buf_size, const ImVec2 size = ImVec2(0,0), ImGuiInputTextFlags flags = ImGuiInputTextFlags.None, ImGuiInputTextCallback callback = null, void* user_data = null);
    bool igInputTextWithHint(const(char)* label, const(char)* hint, char* buf, size_t buf_size, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None, ImGuiInputTextCallback callback = null, void* user_data = null);
    /// flexible button behavior without the visuals, frequently useful to build custom behaviors using the public api (along with IsItemActive, IsItemHovered, etc.)
    bool igInvisibleButton(const(char)* str_id, const ImVec2 size, ImGuiButtonFlags flags = ImGuiButtonFlags.None);
    bool igIsActiveIdUsingNavDir(ImGuiDir dir);
    bool igIsAliasKey(ImGuiKey key);
    /// is any item active?
    bool igIsAnyItemActive();
    /// is any item focused?
    bool igIsAnyItemFocused();
    /// is any item hovered?
    bool igIsAnyItemHovered();
    /// [WILL OBSOLETE] is any mouse button held? This was designed for backends, but prefer having backend maintain a mask of held mouse buttons, because upcoming input queue system will make this invalid.
    bool igIsAnyMouseDown();
    bool igIsClippedEx(const ImRect bb, ImGuiID id);
    bool igIsDragDropActive();
    bool igIsDragDropPayloadBeingAccepted();
    bool igIsGamepadKey(ImGuiKey key);
    /// was the last item just made active (item was previously inactive).
    bool igIsItemActivated();
    /// is the last item active? (e.g. button being held, text field being edited. This will continuously return true while holding mouse button on an item. Items that don't interact will always return false)
    bool igIsItemActive();
    /// This may be useful to apply workaround that a based on distinguish whenever an item is active as a text input field.
    bool igIsItemActiveAsInputText();
    /// is the last item hovered and mouse clicked on? (**)  == IsMouseClicked(mouse_button) && IsItemHovered()Important. (**) this is NOT equivalent to the behavior of e.g. Button(). Read comments in function definition.
    bool igIsItemClicked(ImGuiMouseButton mouse_button = ImGuiMouseButton.Left);
    /// was the last item just made inactive (item was previously active). Useful for Undo/Redo patterns with widgets that require continuous editing.
    bool igIsItemDeactivated();
    /// was the last item just made inactive and made a value change when it was active? (e.g. Slider/Drag moved). Useful for Undo/Redo patterns with widgets that require continuous editing. Note that you may get false positives (some widgets such as Combo()/ListBox()/Selectable() will return true even when clicking an already selected item).
    bool igIsItemDeactivatedAfterEdit();
    /// did the last item modify its underlying value this frame? or was pressed? This is generally the same as the "bool" return value of many widgets.
    bool igIsItemEdited();
    /// is the last item focused for keyboard/gamepad navigation?
    bool igIsItemFocused();
    /// is the last item hovered? (and usable, aka not blocked by a popup, etc.). See ImGuiHoveredFlags for more options.
    bool igIsItemHovered(ImGuiHoveredFlags flags = ImGuiHoveredFlags.None);
    /// was the last item open state toggled? set by TreeNode().
    bool igIsItemToggledOpen();
    /// Was the last item selection state toggled? Useful if you need the per-item information _before_ reaching EndMultiSelect(). We only returns toggle _event_ in order to handle clipping correctly.
    bool igIsItemToggledSelection();
    /// is the last item visible? (items may be out of sight because of clipping/scrolling)
    bool igIsItemVisible();
    /// was key chord (mods + key) pressed, e.g. you can pass 'ImGuiMod_Ctrl | ImGuiKey_S' as a key-chord. This doesn't do any routing or focus check, please consider using Shortcut() function instead.
    bool igIsKeyChordPressed_Nil(ImGuiKeyChord key_chord);
    bool igIsKeyChordPressed_InputFlags(ImGuiKeyChord key_chord, ImGuiInputFlags flags, ImGuiID owner_id = 0);
    /// is key being held.
    bool igIsKeyDown_Nil(ImGuiKey key);
    bool igIsKeyDown_ID(ImGuiKey key, ImGuiID owner_id);
    /// was key pressed (went from !Down to Down)? if repeat=true, uses io.KeyRepeatDelay / KeyRepeatRate
    bool igIsKeyPressed_Bool(ImGuiKey key, bool repeat = true);
    /// Important: when transitioning from old to new IsKeyPressed(): old API has "bool repeat = true", so would default to repeat. New API requiress explicit ImGuiInputFlags_Repeat.
    bool igIsKeyPressed_InputFlags(ImGuiKey key, ImGuiInputFlags flags, ImGuiID owner_id = 0);
    /// was key released (went from Down to !Down)?
    bool igIsKeyReleased_Nil(ImGuiKey key);
    bool igIsKeyReleased_ID(ImGuiKey key, ImGuiID owner_id);
    bool igIsKeyboardKey(ImGuiKey key);
    bool igIsLRModKey(ImGuiKey key);
    bool igIsLegacyKey(ImGuiKey key);
    /// did mouse button clicked? (went from !Down to Down). Same as GetMouseClickedCount() == 1.
    bool igIsMouseClicked_Bool(ImGuiMouseButton button, bool repeat = false);
    bool igIsMouseClicked_InputFlags(ImGuiMouseButton button, ImGuiInputFlags flags, ImGuiID owner_id = 0);
    /// did mouse button double-clicked? Same as GetMouseClickedCount() == 2. (note that a double-click will also report IsMouseClicked() == true)
    bool igIsMouseDoubleClicked_Nil(ImGuiMouseButton button);
    bool igIsMouseDoubleClicked_ID(ImGuiMouseButton button, ImGuiID owner_id);
    /// is mouse button held?
    bool igIsMouseDown_Nil(ImGuiMouseButton button);
    bool igIsMouseDown_ID(ImGuiMouseButton button, ImGuiID owner_id);
    bool igIsMouseDragPastThreshold(ImGuiMouseButton button, float lock_threshold = -1.0f);
    /// is mouse dragging? (uses io.MouseDraggingThreshold if lock_threshold < 0.0f)
    bool igIsMouseDragging(ImGuiMouseButton button, float lock_threshold = -1.0f);
    /// is mouse hovering given bounding rect (in screen space). clipped by current clipping settings, but disregarding of other consideration of focus/window ordering/popup-block.
    bool igIsMouseHoveringRect(const ImVec2 r_min, const ImVec2 r_max, bool clip = true);
    bool igIsMouseKey(ImGuiKey key);
    /// by convention we use (-FLT_MAX,-FLT_MAX) to denote that there is no mouse available
    bool igIsMousePosValid(const ImVec2* mouse_pos = null);
    /// did mouse button released? (went from Down to !Down)
    bool igIsMouseReleased_Nil(ImGuiMouseButton button);
    bool igIsMouseReleased_ID(ImGuiMouseButton button, ImGuiID owner_id);
    /// delayed mouse release (use very sparingly!). Generally used with 'delay >= io.MouseDoubleClickTime' + combined with a 'io.MouseClickedLastCount==1' test. This is a very rarely used UI idiom, but some apps use this: e.g. MS Explorer single click on an icon to rename.
    bool igIsMouseReleasedWithDelay(ImGuiMouseButton button, float delay);
    bool igIsNamedKey(ImGuiKey key);
    bool igIsNamedKeyOrMod(ImGuiKey key);
    /// return true if the popup is open.
    bool igIsPopupOpen_Str(const(char)* str_id, ImGuiPopupFlags flags = ImGuiPopupFlags.MouseButtonLeft);
    bool igIsPopupOpen_ID(ImGuiID id, ImGuiPopupFlags popup_flags);
    /// test if rectangle (of given size, starting from cursor position) is visible / not clipped.
    bool igIsRectVisible_Nil(const ImVec2 size);
    /// test if rectangle (in screen space) is visible / not clipped. to perform coarse clipping on user's side.
    bool igIsRectVisible_Vec2(const ImVec2 rect_min, const ImVec2 rect_max);
    bool igIsWindowAbove(ImGuiWindow* potential_above, ImGuiWindow* potential_below);
    bool igIsWindowAppearing();
    bool igIsWindowChildOf(ImGuiWindow* window, ImGuiWindow* potential_parent, bool popup_hierarchy, bool dock_hierarchy);
    bool igIsWindowCollapsed();
    bool igIsWindowContentHoverable(ImGuiWindow* window, ImGuiHoveredFlags flags = ImGuiHoveredFlags.None);
    /// is current window docked into another window?
    bool igIsWindowDocked();
    /// is current window focused? or its root/child, depending on flags. see flags for options.
    bool igIsWindowFocused(ImGuiFocusedFlags flags = ImGuiFocusedFlags.None);
    /// is current window hovered and hoverable (e.g. not blocked by a popup/modal)? See ImGuiHoveredFlags_ for options. IMPORTANT: If you are trying to check whether your mouse should be dispatched to Dear ImGui or to your underlying app, you should not use this function! Use the 'io.WantCaptureMouse' boolean for that! Refer to FAQ entry "How can I tell whether to dispatch mouse/keyboard to Dear ImGui or my application?" for details.
    bool igIsWindowHovered(ImGuiHoveredFlags flags = ImGuiHoveredFlags.None);
    bool igIsWindowNavFocusable(ImGuiWindow* window);
    bool igIsWindowWithinBeginStackOf(ImGuiWindow* window, ImGuiWindow* potential_parent);
    bool igItemAdd(const ImRect bb, ImGuiID id, const ImRect* nav_bb = null, ImGuiItemFlags extra_flags = ImGuiItemFlags.None);
    bool igItemHoverable(const ImRect bb, ImGuiID id, ImGuiItemFlags item_flags);
    void igItemSize_Vec2(const ImVec2 size, float text_baseline_y = -1.0f);
    /// FIXME: This is a misleading API since we expect CursorPos to be bb.Min.
    void igItemSize_Rect(const ImRect bb, float text_baseline_y = -1.0f);
    void igKeepAliveID(ImGuiID id);
    /// display text+label aligned the same way as value+label widgets
    void igLabelText(const(char)* label, const(char)* fmt, ...);
    void igLabelTextV(const(char)* label, const(char)* fmt, va_list args);
    bool igListBox_Str_arr(const(char)* label, int* current_item, const(char)** items, int items_count, int height_in_items = -1);
    bool igListBox_FnStrPtr(const(char)* label, int* current_item, const(char)* function(void* user_data,int idx) getter, void* user_data, int items_count, int height_in_items = -1);
    /// call after CreateContext() and before the first call to NewFrame(). NewFrame() automatically calls LoadIniSettingsFromDisk(io.IniFilename).
    void igLoadIniSettingsFromDisk(const(char)* ini_filename);
    /// call after CreateContext() and before the first call to NewFrame() to provide .ini data from your own data source.
    void igLoadIniSettingsFromMemory(const(char)* ini_data, size_t ini_size = 0);
    const(char)* igLocalizeGetMsg(ImGuiLocKey key);
    void igLocalizeRegisterEntries(const ImGuiLocEntry* entries, int count);
    /// -> BeginCapture() when we design v2 api, for now stay under the radar by using the old name.
    void igLogBegin(ImGuiLogFlags flags, int auto_open_depth);
    /// helper to display buttons for logging to tty/file/clipboard
    void igLogButtons();
    /// stop logging (close file, etc.)
    void igLogFinish();
    void igLogRenderedText(const ImVec2* ref_pos, const(char)* text, const(char)* text_end = null);
    void igLogSetNextTextDecoration(const(char)* prefix, const(char)* suffix);
    /// pass text data straight to log (without being displayed)
    void igLogText(const(char)* fmt, ...);
    void igLogTextV(const(char)* fmt, va_list args);
    /// Start logging/capturing to internal buffer
    void igLogToBuffer(int auto_open_depth = -1);
    /// start logging to OS clipboard
    void igLogToClipboard(int auto_open_depth = -1);
    /// start logging to file
    void igLogToFile(int auto_open_depth = -1, const(char)* filename = null);
    /// start logging to tty (stdout)
    void igLogToTTY(int auto_open_depth = -1);
    void igMarkIniSettingsDirty_Nil();
    void igMarkIniSettingsDirty_WindowPtr(ImGuiWindow* window);
    /// Mark data associated to given item as "edited", used by IsItemDeactivatedAfterEdit() function.
    void igMarkItemEdited(ImGuiID id);
    void* igMemAlloc(size_t size);
    void igMemFree(void* ptr);
    /// return true when activated.
    bool igMenuItem_Bool(const(char)* label, const(char)* shortcut = null, bool selected = false, bool enabled = true);
    /// return true when activated + toggle (*p_selected) if p_selected != NULL
    bool igMenuItem_BoolPtr(const(char)* label, const(char)* shortcut, bool* p_selected, bool enabled = true);
    bool igMenuItemEx(const(char)* label, const(char)* icon, const(char)* shortcut = null, bool selected = false, bool enabled = true);
    ImGuiKey igMouseButtonToKey(ImGuiMouseButton button);
    void igMultiSelectAddSetAll(ImGuiMultiSelectTempData* ms, bool selected);
    void igMultiSelectAddSetRange(ImGuiMultiSelectTempData* ms, bool selected, int range_dir, ImGuiSelectionUserData first_item, ImGuiSelectionUserData last_item);
    void igMultiSelectItemFooter(ImGuiID id, bool* p_selected, bool* p_pressed);
    void igMultiSelectItemHeader(ImGuiID id, bool* p_selected, ImGuiButtonFlags* p_button_flags);
    void igNavClearPreferredPosForAxis(ImGuiAxis axis);
    void igNavHighlightActivated(ImGuiID id);
    void igNavInitRequestApplyResult();
    void igNavInitWindow(ImGuiWindow* window, bool force_reinit);
    void igNavMoveRequestApplyResult();
    bool igNavMoveRequestButNoResultYet();
    void igNavMoveRequestCancel();
    void igNavMoveRequestForward(ImGuiDir move_dir, ImGuiDir clip_dir, ImGuiNavMoveFlags move_flags, ImGuiScrollFlags scroll_flags);
    void igNavMoveRequestResolveWithLastItem(ImGuiNavItemData* result);
    void igNavMoveRequestResolveWithPastTreeNode(ImGuiNavItemData* result, const ImGuiTreeNodeStackData* tree_node_data);
    void igNavMoveRequestSubmit(ImGuiDir move_dir, ImGuiDir clip_dir, ImGuiNavMoveFlags move_flags, ImGuiScrollFlags scroll_flags);
    void igNavMoveRequestTryWrapping(ImGuiWindow* window, ImGuiNavMoveFlags move_flags);
    void igNavUpdateCurrentWindowIsScrollPushableX();
    /// start a new Dear ImGui frame, you can submit any command from this point until Render()/EndFrame().
    void igNewFrame();
    /// undo a SameLine() or force a new line when in a horizontal-layout context.
    void igNewLine();
    /// next column, defaults to current row or next row if the current row is finished
    void igNextColumn();
    /// call to mark popup as open (don't call every frame!).
    void igOpenPopup_Str(const(char)* str_id, ImGuiPopupFlags popup_flags = ImGuiPopupFlags.MouseButtonLeft);
    /// id overload to facilitate calling from nested stacks
    void igOpenPopup_ID(ImGuiID id, ImGuiPopupFlags popup_flags = ImGuiPopupFlags.MouseButtonLeft);
    void igOpenPopupEx(ImGuiID id, ImGuiPopupFlags popup_flags = ImGuiPopupFlags.None);
    /// helper to open popup when clicked on last item. Default to ImGuiPopupFlags_MouseButtonRight == 1. (note: actually triggers on the mouse _released_ event to be consistent with popup behaviors)
    void igOpenPopupOnItemClick(const(char)* str_id = null, ImGuiPopupFlags popup_flags = ImGuiPopupFlags.MouseButtonDefault_);
    int igPlotEx(ImGuiPlotType plot_type, const(char)* label, float function(void* data,int idx) values_getter, void* data, int values_count, int values_offset, const(char)* overlay_text, float scale_min, float scale_max, const ImVec2 size_arg);
    void igPlotHistogram_FloatPtr(const(char)* label, const float* values, int values_count, int values_offset = 0, const(char)* overlay_text = null, float scale_min = float.max, float scale_max = float.max, ImVec2 graph_size = ImVec2(0,0), int stride = float.sizeof);
    void igPlotHistogram_FnFloatPtr(const(char)* label, float function(void* data,int idx) values_getter, void* data, int values_count, int values_offset = 0, const(char)* overlay_text = null, float scale_min = float.max, float scale_max = float.max, ImVec2 graph_size = ImVec2(0,0));
    void igPlotLines_FloatPtr(const(char)* label, const float* values, int values_count, int values_offset = 0, const(char)* overlay_text = null, float scale_min = float.max, float scale_max = float.max, ImVec2 graph_size = ImVec2(0,0), int stride = float.sizeof);
    void igPlotLines_FnFloatPtr(const(char)* label, float function(void* data,int idx) values_getter, void* data, int values_count, int values_offset = 0, const(char)* overlay_text = null, float scale_min = float.max, float scale_max = float.max, ImVec2 graph_size = ImVec2(0,0));
    void igPopClipRect();
    void igPopColumnsBackground();
    void igPopFocusScope();
    void igPopFont();
    void igPopFontSize();
    /// pop from the ID stack.
    void igPopID();
    void igPopItemFlag();
    void igPopItemWidth();
    void igPopPasswordFont();
    void igPopStyleColor(int count = 1);
    void igPopStyleVar(int count = 1);
    void igPopTextWrapPos();
    void igProgressBar(float fraction, const ImVec2 size_arg = ImVec2(-float.min_normal,0), const(char)* overlay = null);
    void igPushClipRect(const ImVec2 clip_rect_min, const ImVec2 clip_rect_max, bool intersect_with_current_clip_rect);
    void igPushColumnClipRect(int column_index);
    void igPushColumnsBackground();
    void igPushFocusScope(ImGuiID id);
    /// use NULL as a shortcut to push default font. Use <0.0f to keep current font size.
    void igPushFont(ImFont* font, float font_size_base = -1);
    void igPushFontSize(float font_size_base);
    /// push string into the ID stack (will hash string).
    void igPushID_Str(const(char)* str_id);
    /// push string into the ID stack (will hash string).
    void igPushID_StrStr(const(char)* str_id_begin, const(char)* str_id_end);
    /// push pointer into the ID stack (will hash pointer).
    void igPushID_Ptr(const void* ptr_id);
    /// push integer into the ID stack (will hash integer).
    void igPushID_Int(int int_id);
    /// modify specified shared item flag, e.g. PushItemFlag(ImGuiItemFlags_NoTabStop, true)
    void igPushItemFlag(ImGuiItemFlags option, bool enabled);
    /// push width of items for common large "item+label" widgets. >0.0f: width in pixels, <0.0f align xx pixels to the right of window (so -FLT_MIN always align width to the right side).
    void igPushItemWidth(float item_width);
    void igPushMultiItemsWidths(int components, float width_full);
    /// Push given value as-is at the top of the ID stack (whereas PushID combines old and new hashes)
    void igPushOverrideID(ImGuiID id);
    void igPushPasswordFont();
    /// modify a style color. always use this if you modify the style after NewFrame().
    void igPushStyleColor_U32(ImGuiCol idx, ImU32 col);
    void igPushStyleColor_Vec4(ImGuiCol idx, const ImVec4 col);
    /// modify a style float variable. always use this if you modify the style after NewFrame()!
    void igPushStyleVar_Float(ImGuiStyleVar idx, float val);
    /// modify a style ImVec2 variable. "
    void igPushStyleVar_Vec2(ImGuiStyleVar idx, const ImVec2 val);
    /// modify X component of a style ImVec2 variable. "
    void igPushStyleVarX(ImGuiStyleVar idx, float val_x);
    /// modify Y component of a style ImVec2 variable. "
    void igPushStyleVarY(ImGuiStyleVar idx, float val_y);
    /// push word-wrapping position for Text*() commands. < 0.0f: no wrapping; 0.0f: wrap to end of window (or column); > 0.0f: wrap at 'wrap_pos_x' position in window local space
    void igPushTextWrapPos(float wrap_local_pos_x = 0.0f);
    /// use with e.g. if (RadioButton("one", my_value==1))  my_value = 1; 
    bool igRadioButton_Bool(const(char)* label, bool active);
    /// shortcut to handle the above pattern when value is an integer
    bool igRadioButton_IntPtr(const(char)* label, int* v, int v_button);
    void igRegisterFontAtlas(ImFontAtlas* atlas);
    /// Register external texture
    void igRegisterUserTexture(ImTextureData* tex);
    void igRemoveContextHook(ImGuiContext* context, ImGuiID hook_to_remove);
    void igRemoveSettingsHandler(const(char)* type_name);
    /// ends the Dear ImGui frame, finalize the draw data. You can then get call GetDrawData().
    void igRender();
    void igRenderArrow(ImDrawList* draw_list, ImVec2 pos, ImU32 col, ImGuiDir dir, float scale = 1.0f);
    void igRenderArrowDockMenu(ImDrawList* draw_list, ImVec2 p_min, float sz, ImU32 col);
    void igRenderArrowPointingAt(ImDrawList* draw_list, ImVec2 pos, ImVec2 half_sz, ImGuiDir direction, ImU32 col);
    void igRenderBullet(ImDrawList* draw_list, ImVec2 pos, ImU32 col);
    void igRenderCheckMark(ImDrawList* draw_list, ImVec2 pos, ImU32 col, float sz);
    void igRenderColorRectWithAlphaCheckerboard(ImDrawList* draw_list, ImVec2 p_min, ImVec2 p_max, ImU32 fill_col, float grid_step, ImVec2 grid_off, float rounding = 0.0f, ImDrawFlags flags = ImDrawFlags.None);
    void igRenderDragDropTargetRect(const ImRect bb, const ImRect item_clip_rect);
    void igRenderFrame(ImVec2 p_min, ImVec2 p_max, ImU32 fill_col, bool borders = true, float rounding = 0.0f);
    void igRenderFrameBorder(ImVec2 p_min, ImVec2 p_max, float rounding = 0.0f);
    void igRenderMouseCursor(ImVec2 pos, float scale, ImGuiMouseCursor mouse_cursor, ImU32 col_fill, ImU32 col_border, ImU32 col_shadow);
    /// Navigation highlight
    void igRenderNavCursor(const ImRect bb, ImGuiID id, ImGuiNavRenderCursorFlags flags = ImGuiNavRenderCursorFlags.None);
    /// call in main loop. will call RenderWindow/SwapBuffers platform functions for each secondary viewport which doesn't have the ImGuiViewportFlags_Minimized flag set. May be reimplemented by user for custom rendering needs.
    void igRenderPlatformWindowsDefault(void* platform_render_arg = null, void* renderer_render_arg = null);
    void igRenderRectFilledRangeH(ImDrawList* draw_list, const ImRect rect, ImU32 col, float x_start_norm, float x_end_norm, float rounding);
    void igRenderRectFilledWithHole(ImDrawList* draw_list, const ImRect outer, const ImRect inner, ImU32 col, float rounding);
    void igRenderText(ImVec2 pos, const(char)* text, const(char)* text_end = null, bool hide_text_after_hash = true);
    void igRenderTextClipped(const ImVec2 pos_min, const ImVec2 pos_max, const(char)* text, const(char)* text_end, const ImVec2* text_size_if_known, const ImVec2 alignment = ImVec2(0,0), const ImRect* clip_rect = null);
    void igRenderTextClippedEx(ImDrawList* draw_list, const ImVec2 pos_min, const ImVec2 pos_max, const(char)* text, const(char)* text_end, const ImVec2* text_size_if_known, const ImVec2 alignment = ImVec2(0,0), const ImRect* clip_rect = null);
    void igRenderTextEllipsis(ImDrawList* draw_list, const ImVec2 pos_min, const ImVec2 pos_max, float ellipsis_max_x, const(char)* text, const(char)* text_end, const ImVec2* text_size_if_known);
    void igRenderTextWrapped(ImVec2 pos, const(char)* text, const(char)* text_end, float wrap_width);
    //
    void igResetMouseDragDelta(ImGuiMouseButton button = ImGuiMouseButton.Left);
    /// call between widgets or groups to layout them horizontally. X position given in window coordinates.
    void igSameLine(float offset_from_start_x = 0.0f, float spacing = -1.0f);
    /// this is automatically called (if io.IniFilename is not empty) a few seconds after any modification that should be reflected in the .ini file (and also by DestroyContext).
    void igSaveIniSettingsToDisk(const(char)* ini_filename);
    /// return a zero-terminated string with the .ini data which you can save by your own mean. call when io.WantSaveIniSettings is set, then save data by your own mean and clear io.WantSaveIniSettings.
    const(char)* igSaveIniSettingsToMemory(size_t* out_ini_size = null);
    void igScaleWindowsInViewport(ImGuiViewportP* viewport, float scale);
    void igScrollToBringRectIntoView(ImGuiWindow* window, const ImRect rect);
    void igScrollToItem(ImGuiScrollFlags flags = ImGuiScrollFlags.None);
    void igScrollToRect(ImGuiWindow* window, const ImRect rect, ImGuiScrollFlags flags = ImGuiScrollFlags.None);
    void igScrollToRectEx(ImVec2* pOut, ImGuiWindow* window, const ImRect rect, ImGuiScrollFlags flags = ImGuiScrollFlags.None);
    void igScrollbar(ImGuiAxis axis);
    bool igScrollbarEx(const ImRect bb, ImGuiID id, ImGuiAxis axis, ImS64* p_scroll_v, ImS64 avail_v, ImS64 contents_v, ImDrawFlags draw_rounding_flags = ImDrawFlags.None);
    /// "bool selected" carry the selection state (read-only). Selectable() is clicked is returns true so you can modify your selection state. size.x==0.0: use remaining width, size.x>0.0: specify width. size.y==0.0: use label height, size.y>0.0: specify height
    bool igSelectable_Bool(const(char)* label, bool selected = false, ImGuiSelectableFlags flags = ImGuiSelectableFlags.None, const ImVec2 size = ImVec2(0,0));
    /// "bool* p_selected" point to the selection state (read-write), as a convenient helper.
    bool igSelectable_BoolPtr(const(char)* label, bool* p_selected, ImGuiSelectableFlags flags = ImGuiSelectableFlags.None, const ImVec2 size = ImVec2(0,0));
    /// separator, generally horizontal. inside a menu bar or in horizontal layout mode, this becomes a vertical separator.
    void igSeparator();
    void igSeparatorEx(ImGuiSeparatorFlags flags, float thickness = 1.0f);
    /// currently: formatted text with a horizontal line
    void igSeparatorText(const(char)* label);
    void igSeparatorTextEx(ImGuiID id, const(char)* label, const(char)* label_end, float extra_width);
    void igSetActiveID(ImGuiID id, ImGuiWindow* window);
    void igSetActiveIdUsingAllKeyboardKeys();
    void igSetAllocatorFunctions(ImGuiMemAllocFunc alloc_func, ImGuiMemFreeFunc free_func, void* user_data = null);
    void igSetClipboardText(const(char)* text);
    /// initialize current options (generally on application startup) if you want to select a default format, picker type, etc. User will be able to change many settings, unless you pass the _NoOptions flag to your calls.
    void igSetColorEditOptions(ImGuiColorEditFlags flags);
    /// set position of column line (in pixels, from the left side of the contents region). pass -1 to use current column
    void igSetColumnOffset(int column_index, float offset_x);
    /// set column width (in pixels). pass -1 to use current column
    void igSetColumnWidth(int column_index, float width);
    void igSetCurrentContext(ImGuiContext* ctx);
    void igSetCurrentFont(ImFont* font, float font_size_before_scaling, float font_size_after_scaling);
    void igSetCurrentViewport(ImGuiWindow* window, ImGuiViewportP* viewport);
    /// [window-local] "
    void igSetCursorPos(const ImVec2 local_pos);
    /// [window-local] "
    void igSetCursorPosX(float local_x);
    /// [window-local] "
    void igSetCursorPosY(float local_y);
    /// cursor position, absolute coordinates. THIS IS YOUR BEST FRIEND.
    void igSetCursorScreenPos(const ImVec2 pos);
    /// type is a user defined string of maximum 32 characters. Strings starting with '_' are reserved for dear imgui internal types. Data is copied and held by imgui. Return true when payload has been accepted.
    bool igSetDragDropPayload(const(char)* type, const void* data, size_t sz, ImGuiCond cond = ImGuiCond.None);
    void igSetFocusID(ImGuiID id, ImGuiWindow* window);
    void igSetFontRasterizerDensity(float rasterizer_density);
    void igSetHoveredID(ImGuiID id);
    /// make last item the default focused item of a newly appearing window.
    void igSetItemDefaultFocus();
    /// Set key owner to last item ID if it is hovered or active. Equivalent to 'if (IsItemHovered() || IsItemActive())  SetKeyOwner(key, GetItemID());'.
    void igSetItemKeyOwner_Nil(ImGuiKey key);
    /// Set key owner to last item if it is hovered or active. Equivalent to 'if (IsItemHovered() || IsItemActive())  SetKeyOwner(key, GetItemID());'.
    void igSetItemKeyOwner_InputFlags(ImGuiKey key, ImGuiInputFlags flags);
    /// set a text-only tooltip if preceding item was hovered. override any previous call to SetTooltip().
    void igSetItemTooltip(const(char)* fmt, ...);
    void igSetItemTooltipV(const(char)* fmt, va_list args);
    void igSetKeyOwner(ImGuiKey key, ImGuiID owner_id, ImGuiInputFlags flags = ImGuiInputFlags.None);
    void igSetKeyOwnersForKeyChord(ImGuiKeyChord key, ImGuiID owner_id, ImGuiInputFlags flags = ImGuiInputFlags.None);
    /// focus keyboard on the next widget. Use positive 'offset' to access sub components of a multiple component widget. Use -1 to access previous widget.
    void igSetKeyboardFocusHere(int offset = 0);
    void igSetLastItemData(ImGuiID item_id, ImGuiItemFlags item_flags, ImGuiItemStatusFlags status_flags, const ImRect item_rect);
    /// set desired mouse cursor shape
    void igSetMouseCursor(ImGuiMouseCursor cursor_type);
    /// alter visibility of keyboard/gamepad cursor. by default: show when using an arrow key, hide when clicking with mouse.
    void igSetNavCursorVisible(bool visible);
    void igSetNavCursorVisibleAfterMove();
    void igSetNavFocusScope(ImGuiID focus_scope_id);
    void igSetNavID(ImGuiID id, ImGuiNavLayer nav_layer, ImGuiID focus_scope_id, const ImRect rect_rel);
    void igSetNavWindow(ImGuiWindow* window);
    /// Override io.WantCaptureKeyboard flag next frame (said flag is left for your application to handle, typically when true it instructs your app to ignore inputs). e.g. force capture keyboard when your widget is being hovered. This is equivalent to setting "io.WantCaptureKeyboard = want_capture_keyboard"; after the next NewFrame() call.
    void igSetNextFrameWantCaptureKeyboard(bool want_capture_keyboard);
    /// Override io.WantCaptureMouse flag next frame (said flag is left for your application to handle, typical when true it instructs your app to ignore inputs). This is equivalent to setting "io.WantCaptureMouse = want_capture_mouse;" after the next NewFrame() call.
    void igSetNextFrameWantCaptureMouse(bool want_capture_mouse);
    /// allow next item to be overlapped by a subsequent item. Useful with invisible buttons, selectable, treenode covering an area where subsequent items may need to be added. Note that both Selectable() and TreeNode() have dedicated flags doing this.
    void igSetNextItemAllowOverlap();
    /// set next TreeNode/CollapsingHeader open state.
    void igSetNextItemOpen(bool is_open, ImGuiCond cond = ImGuiCond.None);
    void igSetNextItemRefVal(ImGuiDataType data_type, void* p_data);
    void igSetNextItemSelectionUserData(ImGuiSelectionUserData selection_user_data);
    void igSetNextItemShortcut(ImGuiKeyChord key_chord, ImGuiInputFlags flags = ImGuiInputFlags.None);
    /// set id to use for open/close storage (default to same as item id).
    void igSetNextItemStorageID(ImGuiID storage_id);
    /// set width of the _next_ common large "item+label" widget. >0.0f: width in pixels, <0.0f align xx pixels to the right of window (so -FLT_MIN always align width to the right side)
    void igSetNextItemWidth(float item_width);
    /// set next window background color alpha. helper to easily override the Alpha component of ImGuiCol_WindowBg/ChildBg/PopupBg. you may also use ImGuiWindowFlags_NoBackground.
    void igSetNextWindowBgAlpha(float alpha);
    /// set next window class (control docking compatibility + provide hints to platform backend via custom viewport flags and platform parent/child relationship)
    void igSetNextWindowClass(const ImGuiWindowClass* window_class);
    /// set next window collapsed state. call before Begin()
    void igSetNextWindowCollapsed(bool collapsed, ImGuiCond cond = ImGuiCond.None);
    /// set next window content size (~ scrollable client area, which enforce the range of scrollbars). Not including window decorations (title bar, menu bar, etc.) nor WindowPadding. set an axis to 0.0f to leave it automatic. call before Begin()
    void igSetNextWindowContentSize(const ImVec2 size);
    /// set next window dock id
    void igSetNextWindowDockID(ImGuiID dock_id, ImGuiCond cond = ImGuiCond.None);
    /// set next window to be focused / top-most. call before Begin()
    void igSetNextWindowFocus();
    /// set next window position. call before Begin(). use pivot=(0.5f,0.5f) to center on given point, etc.
    void igSetNextWindowPos(const ImVec2 pos, ImGuiCond cond = ImGuiCond.None, const ImVec2 pivot = ImVec2(0,0));
    void igSetNextWindowRefreshPolicy(ImGuiWindowRefreshFlags flags);
    /// set next window scrolling value (use < 0.0f to not affect a given axis).
    void igSetNextWindowScroll(const ImVec2 scroll);
    /// set next window size. set axis to 0.0f to force an auto-fit on this axis. call before Begin()
    void igSetNextWindowSize(const ImVec2 size, ImGuiCond cond = ImGuiCond.None);
    /// set next window size limits. use 0.0f or FLT_MAX if you don't want limits. Use -1 for both min and max of same axis to preserve current size (which itself is a constraint). Use callback to apply non-trivial programmatic constraints.
    void igSetNextWindowSizeConstraints(const ImVec2 size_min, const ImVec2 size_max, ImGuiSizeCallback custom_callback = null, void* custom_callback_data = null);
    /// set next window viewport
    void igSetNextWindowViewport(ImGuiID viewport_id);
    /// adjust scrolling amount to make given position visible. Generally GetCursorStartPos() + offset to compute a valid position.
    void igSetScrollFromPosX_Float(float local_x, float center_x_ratio = 0.5f);
    void igSetScrollFromPosX_WindowPtr(ImGuiWindow* window, float local_x, float center_x_ratio);
    /// adjust scrolling amount to make given position visible. Generally GetCursorStartPos() + offset to compute a valid position.
    void igSetScrollFromPosY_Float(float local_y, float center_y_ratio = 0.5f);
    void igSetScrollFromPosY_WindowPtr(ImGuiWindow* window, float local_y, float center_y_ratio);
    /// adjust scrolling amount to make current cursor position visible. center_x_ratio=0.0: left, 0.5: center, 1.0: right. When using to make a "default/current item" visible, consider using SetItemDefaultFocus() instead.
    void igSetScrollHereX(float center_x_ratio = 0.5f);
    /// adjust scrolling amount to make current cursor position visible. center_y_ratio=0.0: top, 0.5: center, 1.0: bottom. When using to make a "default/current item" visible, consider using SetItemDefaultFocus() instead.
    void igSetScrollHereY(float center_y_ratio = 0.5f);
    /// set scrolling amount [0 .. GetScrollMaxX()]
    void igSetScrollX_Float(float scroll_x);
    void igSetScrollX_WindowPtr(ImGuiWindow* window, float scroll_x);
    /// set scrolling amount [0 .. GetScrollMaxY()]
    void igSetScrollY_Float(float scroll_y);
    void igSetScrollY_WindowPtr(ImGuiWindow* window, float scroll_y);
    /// owner_id needs to be explicit and cannot be 0
    bool igSetShortcutRouting(ImGuiKeyChord key_chord, ImGuiInputFlags flags, ImGuiID owner_id);
    /// replace current window storage with our own (if you want to manipulate it yourself, typically clear subsection of it)
    void igSetStateStorage(ImGuiStorage* storage);
    /// notify TabBar or Docking system of a closed tab/window ahead (useful to reduce visual flicker on reorderable tab bars). For tab-bar: call after BeginTabBar() and before Tab submissions. Otherwise call with a window name.
    void igSetTabItemClosed(const(char)* tab_or_docked_window_label);
    /// set a text-only tooltip. Often used after a ImGui::IsItemHovered() check. Override any previous call to SetTooltip().
    void igSetTooltip(const(char)* fmt, ...);
    void igSetTooltipV(const(char)* fmt, va_list args);
    void igSetWindowClipRectBeforeSetChannel(ImGuiWindow* window, const ImRect clip_rect);
    /// (not recommended) set current window collapsed state. prefer using SetNextWindowCollapsed().
    void igSetWindowCollapsed_Bool(bool collapsed, ImGuiCond cond = ImGuiCond.None);
    /// set named window collapsed state
    void igSetWindowCollapsed_Str(const(char)* name, bool collapsed, ImGuiCond cond = ImGuiCond.None);
    void igSetWindowCollapsed_WindowPtr(ImGuiWindow* window, bool collapsed, ImGuiCond cond = ImGuiCond.None);
    void igSetWindowDock(ImGuiWindow* window, ImGuiID dock_id, ImGuiCond cond);
    /// (not recommended) set current window to be focused / top-most. prefer using SetNextWindowFocus().
    void igSetWindowFocus_Nil();
    /// set named window to be focused / top-most. use NULL to remove focus.
    void igSetWindowFocus_Str(const(char)* name);
    void igSetWindowHiddenAndSkipItemsForCurrentFrame(ImGuiWindow* window);
    void igSetWindowHitTestHole(ImGuiWindow* window, const ImVec2 pos, const ImVec2 size);
    /// You may also use SetNextWindowClass()'s FocusRouteParentWindowId field.
    void igSetWindowParentWindowForFocusRoute(ImGuiWindow* window, ImGuiWindow* parent_window);
    /// (not recommended) set current window position - call within Begin()/End(). prefer using SetNextWindowPos(), as this may incur tearing and side-effects.
    void igSetWindowPos_Vec2(const ImVec2 pos, ImGuiCond cond = ImGuiCond.None);
    /// set named window position.
    void igSetWindowPos_Str(const(char)* name, const ImVec2 pos, ImGuiCond cond = ImGuiCond.None);
    void igSetWindowPos_WindowPtr(ImGuiWindow* window, const ImVec2 pos, ImGuiCond cond = ImGuiCond.None);
    /// (not recommended) set current window size - call within Begin()/End(). set to ImVec2(0, 0) to force an auto-fit. prefer using SetNextWindowSize(), as this may incur tearing and minor side-effects.
    void igSetWindowSize_Vec2(const ImVec2 size, ImGuiCond cond = ImGuiCond.None);
    /// set named window size. set axis to 0.0f to force an auto-fit on this axis.
    void igSetWindowSize_Str(const(char)* name, const ImVec2 size, ImGuiCond cond = ImGuiCond.None);
    void igSetWindowSize_WindowPtr(ImGuiWindow* window, const ImVec2 size, ImGuiCond cond = ImGuiCond.None);
    void igSetWindowViewport(ImGuiWindow* window, ImGuiViewportP* viewport);
    void igShadeVertsLinearColorGradientKeepAlpha(ImDrawList* draw_list, int vert_start_idx, int vert_end_idx, ImVec2 gradient_p0, ImVec2 gradient_p1, ImU32 col0, ImU32 col1);
    void igShadeVertsLinearUV(ImDrawList* draw_list, int vert_start_idx, int vert_end_idx, const ImVec2 a, const ImVec2 b, const ImVec2 uv_a, const ImVec2 uv_b, bool clamp);
    void igShadeVertsTransformPos(ImDrawList* draw_list, int vert_start_idx, int vert_end_idx, const ImVec2 pivot_in, float cos_a, float sin_a, const ImVec2 pivot_out);
    bool igShortcut_Nil(ImGuiKeyChord key_chord, ImGuiInputFlags flags = ImGuiInputFlags.None);
    bool igShortcut_ID(ImGuiKeyChord key_chord, ImGuiInputFlags flags, ImGuiID owner_id);
    /// create About window. display Dear ImGui version, credits and build/system information.
    void igShowAboutWindow(bool* p_open = null);
    /// create Debug Log window. display a simplified log of important dear imgui events.
    void igShowDebugLogWindow(bool* p_open = null);
    /// create Demo window. demonstrate most ImGui features. call this to learn about the library! try to make it always available in your application!
    void igShowDemoWindow(bool* p_open = null);
    void igShowFontAtlas(ImFontAtlas* atlas);
    /// add font selector block (not a window), essentially a combo listing the loaded fonts.
    void igShowFontSelector(const(char)* label);
    /// create Stack Tool window. hover items with mouse to query information about the source of their unique ID.
    void igShowIDStackToolWindow(bool* p_open = null);
    /// create Metrics/Debugger window. display Dear ImGui internals: windows, draw commands, various internal state, etc.
    void igShowMetricsWindow(bool* p_open = null);
    /// add style editor block (not a window). you can pass in a reference ImGuiStyle structure to compare to, revert to and save to (else it uses the default style)
    void igShowStyleEditor(ImGuiStyle* reference = null);
    /// add style selector block (not a window), essentially a combo listing the default styles.
    bool igShowStyleSelector(const(char)* label);
    /// add basic help/info block (not a window): how to manipulate ImGui as an end-user (mouse/keyboard controls).
    void igShowUserGuide();
    void igShrinkWidths(ImGuiShrinkWidthItem* items, int count, float width_excess);
    /// Since 1.60 this is a _private_ function. You can call DestroyContext() to destroy the context created by CreateContext().
    void igShutdown();
    bool igSliderAngle(const(char)* label, float* v_rad, float v_degrees_min = -360.0f, float v_degrees_max = +360.0f, const(char)* format = "%.0f deg", ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    bool igSliderBehavior(const ImRect bb, ImGuiID id, ImGuiDataType data_type, void* p_v, const void* p_min, const void* p_max, const(char)* format, ImGuiSliderFlags flags, ImRect* out_grab_bb);
    /// adjust format to decorate the value with a prefix or a suffix for in-slider labels or unit display.
    bool igSliderFloat(const(char)* label, float* v, float v_min, float v_max, const(char)* format = "%.3f", ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    bool igSliderFloat2(const(char)* label, float[2]*/*[2]*/ v, float v_min, float v_max, const(char)* format = "%.3f", ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    bool igSliderFloat3(const(char)* label, float[3]*/*[3]*/ v, float v_min, float v_max, const(char)* format = "%.3f", ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    bool igSliderFloat4(const(char)* label, float[4]*/*[4]*/ v, float v_min, float v_max, const(char)* format = "%.3f", ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    bool igSliderInt(const(char)* label, int* v, int v_min, int v_max, const(char)* format = "%d", ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    bool igSliderInt2(const(char)* label, int[2]*/*[2]*/ v, int v_min, int v_max, const(char)* format = "%d", ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    bool igSliderInt3(const(char)* label, int[3]*/*[3]*/ v, int v_min, int v_max, const(char)* format = "%d", ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    bool igSliderInt4(const(char)* label, int[4]*/*[4]*/ v, int v_min, int v_max, const(char)* format = "%d", ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    bool igSliderScalar(const(char)* label, ImGuiDataType data_type, void* p_data, const void* p_min, const void* p_max, const(char)* format = null, ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    bool igSliderScalarN(const(char)* label, ImGuiDataType data_type, void* p_data, int components, const void* p_min, const void* p_max, const(char)* format = null, ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    /// button with (FramePadding.y == 0) to easily embed within text
    bool igSmallButton(const(char)* label);
    /// add vertical spacing.
    void igSpacing();
    bool igSplitterBehavior(const ImRect bb, ImGuiID id, ImGuiAxis axis, float* size1, float* size2, float min_size1, float min_size2, float hover_extend = 0.0f, float hover_visibility_delay = 0.0f, ImU32 bg_col = 0);
    void igStartMouseMovingWindow(ImGuiWindow* window);
    void igStartMouseMovingWindowOrNode(ImGuiWindow* window, ImGuiDockNode* node, bool undock);
    /// classic imgui style
    void igStyleColorsClassic(ImGuiStyle* dst = null);
    /// new, recommended style (default)
    void igStyleColorsDark(ImGuiStyle* dst = null);
    /// best used with borders and a custom, thicker font
    void igStyleColorsLight(ImGuiStyle* dst = null);
    void igTabBarAddTab(ImGuiTabBar* tab_bar, ImGuiTabItemFlags tab_flags, ImGuiWindow* window);
    void igTabBarCloseTab(ImGuiTabBar* tab_bar, ImGuiTabItem* tab);
    ImGuiTabItem* igTabBarFindMostRecentlySelectedTabForActiveWindow(ImGuiTabBar* tab_bar);
    ImGuiTabItem* igTabBarFindTabByID(ImGuiTabBar* tab_bar, ImGuiID tab_id);
    ImGuiTabItem* igTabBarFindTabByOrder(ImGuiTabBar* tab_bar, int order);
    ImGuiTabItem* igTabBarGetCurrentTab(ImGuiTabBar* tab_bar);
    const(char)* igTabBarGetTabName(ImGuiTabBar* tab_bar, ImGuiTabItem* tab);
    int igTabBarGetTabOrder(ImGuiTabBar* tab_bar, ImGuiTabItem* tab);
    bool igTabBarProcessReorder(ImGuiTabBar* tab_bar);
    void igTabBarQueueFocus_TabItemPtr(ImGuiTabBar* tab_bar, ImGuiTabItem* tab);
    void igTabBarQueueFocus_Str(ImGuiTabBar* tab_bar, const(char)* tab_name);
    void igTabBarQueueReorder(ImGuiTabBar* tab_bar, ImGuiTabItem* tab, int offset);
    void igTabBarQueueReorderFromMousePos(ImGuiTabBar* tab_bar, ImGuiTabItem* tab, ImVec2 mouse_pos);
    void igTabBarRemoveTab(ImGuiTabBar* tab_bar, ImGuiID tab_id);
    void igTabItemBackground(ImDrawList* draw_list, const ImRect bb, ImGuiTabItemFlags flags, ImU32 col);
    /// create a Tab behaving like a button. return true when clicked. cannot be selected in the tab bar.
    bool igTabItemButton(const(char)* label, ImGuiTabItemFlags flags = ImGuiTabItemFlags.None);
    void igTabItemCalcSize_Str(ImVec2* pOut, const(char)* label, bool has_close_button_or_unsaved_marker);
    void igTabItemCalcSize_WindowPtr(ImVec2* pOut, ImGuiWindow* window);
    bool igTabItemEx(ImGuiTabBar* tab_bar, const(char)* label, bool* p_open, ImGuiTabItemFlags flags, ImGuiWindow* docked_window);
    void igTabItemLabelAndCloseButton(ImDrawList* draw_list, const ImRect bb, ImGuiTabItemFlags flags, ImVec2 frame_padding, const(char)* label, ImGuiID tab_id, ImGuiID close_button_id, bool is_contents_visible, bool* out_just_closed, bool* out_text_clipped);
    void igTabItemSpacing(const(char)* str_id, ImGuiTabItemFlags flags, float width);
    /// submit a row with angled headers for every column with the ImGuiTableColumnFlags_AngledHeader flag. MUST BE FIRST ROW.
    void igTableAngledHeadersRow();
    void igTableAngledHeadersRowEx(ImGuiID row_id, float angle, float max_label_width, const ImGuiTableHeaderData* data, int data_count);
    void igTableBeginApplyRequests(ImGuiTable* table);
    void igTableBeginCell(ImGuiTable* table, int column_n);
    bool igTableBeginContextMenuPopup(ImGuiTable* table);
    void igTableBeginInitMemory(ImGuiTable* table, int columns_count);
    void igTableBeginRow(ImGuiTable* table);
    float igTableCalcMaxColumnWidth(const ImGuiTable* table, int column_n);
    void igTableDrawBorders(ImGuiTable* table);
    void igTableDrawDefaultContextMenu(ImGuiTable* table, ImGuiTableFlags flags_for_section_to_display);
    void igTableEndCell(ImGuiTable* table);
    void igTableEndRow(ImGuiTable* table);
    ImGuiTable* igTableFindByID(ImGuiID id);
    void igTableFixColumnSortDirection(ImGuiTable* table, ImGuiTableColumn* column);
    void igTableGcCompactSettings();
    void igTableGcCompactTransientBuffers_TablePtr(ImGuiTable* table);
    void igTableGcCompactTransientBuffers_TableTempDataPtr(ImGuiTableTempData* table);
    ImGuiTableSettings* igTableGetBoundSettings(ImGuiTable* table);
    void igTableGetCellBgRect(ImRect* pOut, const ImGuiTable* table, int column_n);
    /// return number of columns (value passed to BeginTable)
    int igTableGetColumnCount();
    /// return column flags so you can query their Enabled/Visible/Sorted/Hovered status flags. Pass -1 to use current column.
    ImGuiTableColumnFlags igTableGetColumnFlags(int column_n = -1);
    /// return current column index.
    int igTableGetColumnIndex();
    /// return "" if column didn't have a name declared by TableSetupColumn(). Pass -1 to use current column.
    const(char)* igTableGetColumnName_Int(int column_n = -1);
    const(char)* igTableGetColumnName_TablePtr(const ImGuiTable* table, int column_n);
    ImGuiSortDirection igTableGetColumnNextSortDirection(ImGuiTableColumn* column);
    ImGuiID igTableGetColumnResizeID(ImGuiTable* table, int column_n, int instance_no = 0);
    float igTableGetColumnWidthAuto(ImGuiTable* table, ImGuiTableColumn* column);
    float igTableGetHeaderAngledMaxLabelWidth();
    float igTableGetHeaderRowHeight();
    /// return hovered column. return -1 when table is not hovered. return columns_count if the unused space at the right of visible columns is hovered. Can also use (TableGetColumnFlags() & ImGuiTableColumnFlags_IsHovered) instead.
    int igTableGetHoveredColumn();
    /// Retrieve *PREVIOUS FRAME* hovered row. This difference with TableGetHoveredColumn() is the reason why this is not public yet.
    int igTableGetHoveredRow();
    ImGuiTableInstanceData* igTableGetInstanceData(ImGuiTable* table, int instance_no);
    ImGuiID igTableGetInstanceID(ImGuiTable* table, int instance_no);
    /// return current row index.
    int igTableGetRowIndex();
    /// get latest sort specs for the table (NULL if not sorting).  Lifetime: don't hold on this pointer over multiple frames or past any subsequent call to BeginTable().
    ImGuiTableSortSpecs* igTableGetSortSpecs();
    /// submit one header cell manually (rarely used)
    void igTableHeader(const(char)* label);
    /// submit a row with headers cells based on data provided to TableSetupColumn() + submit context menu
    void igTableHeadersRow();
    void igTableLoadSettings(ImGuiTable* table);
    void igTableMergeDrawChannels(ImGuiTable* table);
    /// append into the next column (or first column of next row if currently in last column). Return true when column is visible.
    bool igTableNextColumn();
    /// append into the first cell of a new row.
    void igTableNextRow(ImGuiTableRowFlags row_flags = ImGuiTableRowFlags.None, float min_row_height = 0.0f);
    void igTableOpenContextMenu(int column_n = -1);
    void igTablePopBackgroundChannel();
    void igTablePopColumnChannel();
    void igTablePushBackgroundChannel();
    void igTablePushColumnChannel(int column_n);
    void igTableRemove(ImGuiTable* table);
    void igTableResetSettings(ImGuiTable* table);
    void igTableSaveSettings(ImGuiTable* table);
    /// change the color of a cell, row, or column. See ImGuiTableBgTarget_ flags for details.
    void igTableSetBgColor(ImGuiTableBgTarget target, ImU32 color, int column_n = -1);
    /// change user accessible enabled/disabled state of a column. Set to false to hide the column. User can use the context menu to change this themselves (right-click in headers, or right-click in columns body with ImGuiTableFlags_ContextMenuInBody)
    void igTableSetColumnEnabled(int column_n, bool v);
    /// append into the specified column. Return true when column is visible.
    bool igTableSetColumnIndex(int column_n);
    void igTableSetColumnSortDirection(int column_n, ImGuiSortDirection sort_direction, bool append_to_sort_specs);
    void igTableSetColumnWidth(int column_n, float width);
    void igTableSetColumnWidthAutoAll(ImGuiTable* table);
    void igTableSetColumnWidthAutoSingle(ImGuiTable* table, int column_n);
    void igTableSettingsAddSettingsHandler();
    ImGuiTableSettings* igTableSettingsCreate(ImGuiID id, int columns_count);
    ImGuiTableSettings* igTableSettingsFindByID(ImGuiID id);
    void igTableSetupColumn(const(char)* label, ImGuiTableColumnFlags flags = ImGuiTableColumnFlags.None, float init_width_or_weight = 0.0f, ImGuiID user_id = 0);
    void igTableSetupDrawChannels(ImGuiTable* table);
    /// lock columns/rows so they stay visible when scrolled.
    void igTableSetupScrollFreeze(int cols, int rows);
    void igTableSortSpecsBuild(ImGuiTable* table);
    void igTableSortSpecsSanitize(ImGuiTable* table);
    void igTableUpdateBorders(ImGuiTable* table);
    void igTableUpdateColumnsWeightFromWidth(ImGuiTable* table);
    void igTableUpdateLayout(ImGuiTable* table);
    void igTeleportMousePos(const ImVec2 pos);
    bool igTempInputIsActive(ImGuiID id);
    bool igTempInputScalar(const ImRect bb, ImGuiID id, const(char)* label, ImGuiDataType data_type, void* p_data, const(char)* format, const void* p_clamp_min = null, const void* p_clamp_max = null);
    bool igTempInputText(const ImRect bb, ImGuiID id, const(char)* label, char* buf, int buf_size, ImGuiInputTextFlags flags);
    /// Test that key is either not owned, either owned by 'owner_id'
    bool igTestKeyOwner(ImGuiKey key, ImGuiID owner_id);
    bool igTestShortcutRouting(ImGuiKeyChord key_chord, ImGuiID owner_id);
    /// formatted text
    void igText(const(char)* fmt, ...);
    /// FIXME-WIP: Works but API is likely to be reworked. This is designed for 1 item on the line. (#7024)
    void igTextAligned(float align_x, float size_x, const(char)* fmt, ...);
    void igTextAlignedV(float align_x, float size_x, const(char)* fmt, va_list args);
    /// shortcut for PushStyleColor(ImGuiCol_Text, col); Text(fmt, ...); PopStyleColor();
    void igTextColored(const ImVec4 col, const(char)* fmt, ...);
    void igTextColoredV(const ImVec4 col, const(char)* fmt, va_list args);
    /// shortcut for PushStyleColor(ImGuiCol_Text, style.Colors[ImGuiCol_TextDisabled]); Text(fmt, ...); PopStyleColor();
    void igTextDisabled(const(char)* fmt, ...);
    void igTextDisabledV(const(char)* fmt, va_list args);
    void igTextEx(const(char)* text, const(char)* text_end = null, ImGuiTextFlags flags = ImGuiTextFlags.None);
    /// hyperlink text button, return true when clicked
    bool igTextLink(const(char)* label);
    /// hyperlink text button, automatically open file/url when clicked
    bool igTextLinkOpenURL(const(char)* label, const(char)* url = null);
    /// raw text without formatting. Roughly equivalent to Text("%s", text) but: A) doesn't require null terminated string if 'text_end' is specified, B) it's faster, no memory copy is done, no buffer size limits, recommended for long chunks of text.
    void igTextUnformatted(const(char)* text, const(char)* text_end = null);
    void igTextV(const(char)* fmt, va_list args);
    /// shortcut for PushTextWrapPos(0.0f); Text(fmt, ...); PopTextWrapPos();. Note that this won't work on an auto-resizing window if there's no other widgets to extend the window width, yoy may need to set a size using SetNextWindowSize().
    void igTextWrapped(const(char)* fmt, ...);
    void igTextWrappedV(const(char)* fmt, va_list args);
    void igTranslateWindowsInViewport(ImGuiViewportP* viewport, const ImVec2 old_pos, const ImVec2 new_pos, const ImVec2 old_size, const ImVec2 new_size);
    bool igTreeNode_Str(const(char)* label);
    /// helper variation to easily decorelate the id from the displayed string. Read the FAQ about why and how to use ID. to align arbitrary text at the same level as a TreeNode() you can use Bullet().
    bool igTreeNode_StrStr(const(char)* str_id, const(char)* fmt, ...);
    /// "
    bool igTreeNode_Ptr(const void* ptr_id, const(char)* fmt, ...);
    bool igTreeNodeBehavior(ImGuiID id, ImGuiTreeNodeFlags flags, const(char)* label, const(char)* label_end = null);
    void igTreeNodeDrawLineToChildNode(const ImVec2 target_pos);
    void igTreeNodeDrawLineToTreePop(const ImGuiTreeNodeStackData* data);
    bool igTreeNodeEx_Str(const(char)* label, ImGuiTreeNodeFlags flags = ImGuiTreeNodeFlags.None);
    bool igTreeNodeEx_StrStr(const(char)* str_id, ImGuiTreeNodeFlags flags, const(char)* fmt, ...);
    bool igTreeNodeEx_Ptr(const void* ptr_id, ImGuiTreeNodeFlags flags, const(char)* fmt, ...);
    bool igTreeNodeExV_Str(const(char)* str_id, ImGuiTreeNodeFlags flags, const(char)* fmt, va_list args);
    bool igTreeNodeExV_Ptr(const void* ptr_id, ImGuiTreeNodeFlags flags, const(char)* fmt, va_list args);
    bool igTreeNodeGetOpen(ImGuiID storage_id);
    void igTreeNodeSetOpen(ImGuiID storage_id, bool open);
    /// Return open state. Consume previous SetNextItemOpen() data, if any. May return true when logging.
    bool igTreeNodeUpdateNextOpen(ImGuiID storage_id, ImGuiTreeNodeFlags flags);
    bool igTreeNodeV_Str(const(char)* str_id, const(char)* fmt, va_list args);
    bool igTreeNodeV_Ptr(const void* ptr_id, const(char)* fmt, va_list args);
    /// ~ Unindent()+PopID()
    void igTreePop();
    /// ~ Indent()+PushID(). Already called by TreeNode() when returning true, but you can call TreePush/TreePop yourself if desired.
    void igTreePush_Str(const(char)* str_id);
    /// "
    void igTreePush_Ptr(const void* ptr_id);
    void igTreePushOverrideID(ImGuiID id);
    int igTypingSelectFindBestLeadingMatch(ImGuiTypingSelectRequest* req, int items_count, const(char)* function(void*,int) get_item_name_func, void* user_data);
    int igTypingSelectFindMatch(ImGuiTypingSelectRequest* req, int items_count, const(char)* function(void*,int) get_item_name_func, void* user_data, int nav_item_idx);
    int igTypingSelectFindNextSingleCharMatch(ImGuiTypingSelectRequest* req, int items_count, const(char)* function(void*,int) get_item_name_func, void* user_data, int nav_item_idx);
    /// move content position back to the left, by indent_w, or style.IndentSpacing if indent_w <= 0
    void igUnindent(float indent_w = 0.0f);
    void igUnregisterFontAtlas(ImFontAtlas* atlas);
    void igUnregisterUserTexture(ImTextureData* tex);
    void igUpdateCurrentFontSize(float restore_font_size_after_scaling);
    void igUpdateHoveredWindowAndCaptureFlags(const ImVec2 mouse_pos);
    void igUpdateInputEvents(bool trickle_fast_inputs);
    void igUpdateMouseMovingWindowEndFrame();
    void igUpdateMouseMovingWindowNewFrame();
    /// call in main loop. will call CreateWindow/ResizeWindow/etc. platform functions for each secondary viewport, and DestroyWindow for each inactive viewport.
    void igUpdatePlatformWindows();
    void igUpdateWindowParentAndRootLinks(ImGuiWindow* window, ImGuiWindowFlags flags, ImGuiWindow* parent_window);
    void igUpdateWindowSkipRefresh(ImGuiWindow* window);
    bool igVSliderFloat(const(char)* label, const ImVec2 size, float* v, float v_min, float v_max, const(char)* format = "%.3f", ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    bool igVSliderInt(const(char)* label, const ImVec2 size, int* v, int v_min, int v_max, const(char)* format = "%d", ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    bool igVSliderScalar(const(char)* label, const ImVec2 size, ImGuiDataType data_type, void* p_data, const void* p_min, const void* p_max, const(char)* format = null, ImGuiSliderFlags flags = ImGuiSliderFlags.None);
    void igValue_Bool(const(char)* prefix, bool b);
    void igValue_Int(const(char)* prefix, int v);
    void igValue_Uint(const(char)* prefix, uint v);
    void igValue_Float(const(char)* prefix, float v, const(char)* float_format = null);
    void igWindowPosAbsToRel(ImVec2* pOut, ImGuiWindow* window, const ImVec2 p);
    void igWindowPosRelToAbs(ImVec2* pOut, ImGuiWindow* window, const ImVec2 p);
    void igWindowRectAbsToRel(ImRect* pOut, ImGuiWindow* window, const ImRect r);
    void igWindowRectRelToAbs(ImRect* pOut, ImGuiWindow* window, const ImRect r);
}

auto igGenFuncC(T)(T func) {
  import std.traits;
  extern(C) ReturnType!T f(Parameters!T args)
  {
    static if (is(ReturnType!T == void)) 
    {
      func(args);
    } else 
    {
      return func(args);
    }
  }

  return &f;
}
pragma(inline):
ImColor*  ImColor_ImColor()
{
    return  ImColor_ImColor_Nil();
}

pragma(inline):
ImColor*  ImColor_ImColor(float r, float g, float b, float a = 1.0f)
{
    return  ImColor_ImColor_Float(r, g, b, a);
}

pragma(inline):
ImColor*  ImColor_ImColor(const ImVec4 col)
{
    return  ImColor_ImColor_Vec4(col);
}

pragma(inline):
ImColor*  ImColor_ImColor(int r, int g, int b, int a = 255)
{
    return  ImColor_ImColor_Int(r, g, b, a);
}

pragma(inline):
ImColor*  ImColor_ImColor(ImU32 rgba)
{
    return  ImColor_ImColor_U32(rgba);
}

pragma(inline):
void  ImDrawList_AddText(ImDrawList* self, const ImVec2 pos, ImU32 col, const(char)* text_begin, const(char)* text_end = null)
{
     ImDrawList_AddText_Vec2(self, pos, col, text_begin, text_end);
}

pragma(inline):
void  ImDrawList_AddText(ImDrawList* self, ImFont* font, float font_size, const ImVec2 pos, ImU32 col, const(char)* text_begin, const(char)* text_end = null, float wrap_width = 0.0f, const(ImVec4)* cpu_fine_clip_rect = null)
{
     ImDrawList_AddText_FontPtr(self, font, font_size, pos, col, text_begin, text_end, wrap_width, cpu_fine_clip_rect);
}

pragma(inline):
ImGuiPtrOrIndex*  ImGuiPtrOrIndex_ImGuiPtrOrIndex(void* ptr)
{
    return  ImGuiPtrOrIndex_ImGuiPtrOrIndex_Ptr(ptr);
}

pragma(inline):
ImGuiPtrOrIndex*  ImGuiPtrOrIndex_ImGuiPtrOrIndex(int index)
{
    return  ImGuiPtrOrIndex_ImGuiPtrOrIndex_Int(index);
}

pragma(inline):
ImGuiStoragePair*  ImGuiStoragePair_ImGuiStoragePair(ImGuiID _key, int _val)
{
    return  ImGuiStoragePair_ImGuiStoragePair_Int(_key, _val);
}

pragma(inline):
ImGuiStoragePair*  ImGuiStoragePair_ImGuiStoragePair(ImGuiID _key, float _val)
{
    return  ImGuiStoragePair_ImGuiStoragePair_Float(_key, _val);
}

pragma(inline):
ImGuiStoragePair*  ImGuiStoragePair_ImGuiStoragePair(ImGuiID _key, void* _val)
{
    return  ImGuiStoragePair_ImGuiStoragePair_Ptr(_key, _val);
}

pragma(inline):
ImGuiStyleMod*  ImGuiStyleMod_ImGuiStyleMod(ImGuiStyleVar idx, int v)
{
    return  ImGuiStyleMod_ImGuiStyleMod_Int(idx, v);
}

pragma(inline):
ImGuiStyleMod*  ImGuiStyleMod_ImGuiStyleMod(ImGuiStyleVar idx, float v)
{
    return  ImGuiStyleMod_ImGuiStyleMod_Float(idx, v);
}

pragma(inline):
ImGuiStyleMod*  ImGuiStyleMod_ImGuiStyleMod(ImGuiStyleVar idx, ImVec2 v)
{
    return  ImGuiStyleMod_ImGuiStyleMod_Vec2(idx, v);
}

pragma(inline):
ImGuiTextRange*  ImGuiTextRange_ImGuiTextRange()
{
    return  ImGuiTextRange_ImGuiTextRange_Nil();
}

pragma(inline):
ImGuiTextRange*  ImGuiTextRange_ImGuiTextRange(const(char)* _b, const(char)* _e)
{
    return  ImGuiTextRange_ImGuiTextRange_Str(_b, _e);
}

pragma(inline):
ImGuiID  ImGuiWindow_GetID(ImGuiWindow* self, const(char)* str, const(char)* str_end = null)
{
    return  ImGuiWindow_GetID_Str(self, str, str_end);
}

pragma(inline):
ImGuiID  ImGuiWindow_GetID(ImGuiWindow* self, const void* ptr)
{
    return  ImGuiWindow_GetID_Ptr(self, ptr);
}

pragma(inline):
ImGuiID  ImGuiWindow_GetID(ImGuiWindow* self, int n)
{
    return  ImGuiWindow_GetID_Int(self, n);
}

pragma(inline):
void  ImRect_Add(ImRect* self, const ImVec2 p)
{
     ImRect_Add_Vec2(self, p);
}

pragma(inline):
void  ImRect_Add(ImRect* self, const ImRect r)
{
     ImRect_Add_Rect(self, r);
}

pragma(inline):
bool  ImRect_Contains(ImRect* self, const ImVec2 p)
{
    return  ImRect_Contains_Vec2(self, p);
}

pragma(inline):
bool  ImRect_Contains(ImRect* self, const ImRect r)
{
    return  ImRect_Contains_Rect(self, r);
}

pragma(inline):
void  ImRect_Expand(ImRect* self, const float amount)
{
     ImRect_Expand_Float(self, amount);
}

pragma(inline):
void  ImRect_Expand(ImRect* self, const ImVec2 amount)
{
     ImRect_Expand_Vec2(self, amount);
}

pragma(inline):
ImRect*  ImRect_ImRect()
{
    return  ImRect_ImRect_Nil();
}

pragma(inline):
ImRect*  ImRect_ImRect(const ImVec2 min, const ImVec2 max)
{
    return  ImRect_ImRect_Vec2(min, max);
}

pragma(inline):
ImRect*  ImRect_ImRect(const ImVec4 v)
{
    return  ImRect_ImRect_Vec4(v);
}

pragma(inline):
ImRect*  ImRect_ImRect(float x1, float y1, float x2, float y2)
{
    return  ImRect_ImRect_Float(x1, y1, x2, y2);
}

pragma(inline):
ImTextureRef*  ImTextureRef_ImTextureRef()
{
    return  ImTextureRef_ImTextureRef_Nil();
}

pragma(inline):
ImTextureRef*  ImTextureRef_ImTextureRef(ImTextureID tex_id)
{
    return  ImTextureRef_ImTextureRef_TextureID(tex_id);
}

pragma(inline):
ImVec1*  ImVec1_ImVec1()
{
    return  ImVec1_ImVec1_Nil();
}

pragma(inline):
ImVec1*  ImVec1_ImVec1(float _x)
{
    return  ImVec1_ImVec1_Float(_x);
}

pragma(inline):
ImVec2*  ImVec2_ImVec2()
{
    return  ImVec2_ImVec2_Nil();
}

pragma(inline):
ImVec2*  ImVec2_ImVec2(float _x, float _y)
{
    return  ImVec2_ImVec2_Float(_x, _y);
}

pragma(inline):
ImVec2i*  ImVec2i_ImVec2i()
{
    return  ImVec2i_ImVec2i_Nil();
}

pragma(inline):
ImVec2i*  ImVec2i_ImVec2i(int _x, int _y)
{
    return  ImVec2i_ImVec2i_Int(_x, _y);
}

pragma(inline):
ImVec2ih*  ImVec2ih_ImVec2ih()
{
    return  ImVec2ih_ImVec2ih_Nil();
}

pragma(inline):
ImVec2ih*  ImVec2ih_ImVec2ih(short _x, short _y)
{
    return  ImVec2ih_ImVec2ih_short(_x, _y);
}

pragma(inline):
ImVec2ih*  ImVec2ih_ImVec2ih(const ImVec2 rhs)
{
    return  ImVec2ih_ImVec2ih_Vec2(rhs);
}

pragma(inline):
ImVec4*  ImVec4_ImVec4()
{
    return  ImVec4_ImVec4_Nil();
}

pragma(inline):
ImVec4*  ImVec4_ImVec4(float _x, float _y, float _z, float _w)
{
    return  ImVec4_ImVec4_Float(_x, _y, _z, _w);
}

pragma(inline):
bool  igBeginChild(const(char)* str_id, const ImVec2 size = ImVec2(0,0), ImGuiChildFlags child_flags = ImGuiChildFlags.None, ImGuiWindowFlags window_flags = ImGuiWindowFlags.None)
{
    return  igBeginChild_Str(str_id, size, child_flags, window_flags);
}

pragma(inline):
bool  igBeginChild(ImGuiID id, const ImVec2 size = ImVec2(0,0), ImGuiChildFlags child_flags = ImGuiChildFlags.None, ImGuiWindowFlags window_flags = ImGuiWindowFlags.None)
{
    return  igBeginChild_ID(id, size, child_flags, window_flags);
}

pragma(inline):
bool  igCheckboxFlags(const(char)* label, int* flags, int flags_value)
{
    return  igCheckboxFlags_IntPtr(label, flags, flags_value);
}

pragma(inline):
bool  igCheckboxFlags(const(char)* label, uint* flags, uint flags_value)
{
    return  igCheckboxFlags_UintPtr(label, flags, flags_value);
}

pragma(inline):
bool  igCheckboxFlags(const(char)* label, ImS64* flags, ImS64 flags_value)
{
    return  igCheckboxFlags_S64Ptr(label, flags, flags_value);
}

pragma(inline):
bool  igCheckboxFlags(const(char)* label, ImU64* flags, ImU64 flags_value)
{
    return  igCheckboxFlags_U64Ptr(label, flags, flags_value);
}

pragma(inline):
bool  igCollapsingHeader(const(char)* label, ImGuiTreeNodeFlags flags = ImGuiTreeNodeFlags.None)
{
    return  igCollapsingHeader_TreeNodeFlags(label, flags);
}

pragma(inline):
bool  igCollapsingHeader(const(char)* label, bool* p_visible, ImGuiTreeNodeFlags flags = ImGuiTreeNodeFlags.None)
{
    return  igCollapsingHeader_BoolPtr(label, p_visible, flags);
}

pragma(inline):
bool  igCombo(const(char)* label, int* current_item, const(char)** items, int items_count, int popup_max_height_in_items = -1)
{
    return  igCombo_Str_arr(label, current_item, items, items_count, popup_max_height_in_items);
}

pragma(inline):
bool  igCombo(const(char)* label, int* current_item, const(char)* items_separated_by_zeros, int popup_max_height_in_items = -1)
{
    return  igCombo_Str(label, current_item, items_separated_by_zeros, popup_max_height_in_items);
}

extern(C) alias igCombo_getter = const(char)* function(void* user_data,int idx);

pragma(inline):
bool  igCombo(const(char)* label, int* current_item, igCombo_getter getter, void* user_data, int items_count, int popup_max_height_in_items = -1)
{
    return  igCombo_FnStrPtr(label, current_item, getter, user_data, items_count, popup_max_height_in_items);
}

pragma(inline):
ImU32  igGetColorU32(ImGuiCol idx, float alpha_mul = 1.0f)
{
    return  igGetColorU32_Col(idx, alpha_mul);
}

pragma(inline):
ImU32  igGetColorU32(const ImVec4 col)
{
    return  igGetColorU32_Vec4(col);
}

pragma(inline):
ImU32  igGetColorU32(ImU32 col, float alpha_mul = 1.0f)
{
    return  igGetColorU32_U32(col, alpha_mul);
}

pragma(inline):
ImDrawList*  igGetForegroundDrawList(ImGuiViewport* viewport = null)
{
    return  igGetForegroundDrawList_ViewportPtr(viewport);
}

pragma(inline):
ImDrawList*  igGetForegroundDrawList(ImGuiWindow* window)
{
    return  igGetForegroundDrawList_WindowPtr(window);
}

pragma(inline):
ImGuiID  igGetID(const(char)* str_id)
{
    return  igGetID_Str(str_id);
}

pragma(inline):
ImGuiID  igGetID(const(char)* str_id_begin, const(char)* str_id_end)
{
    return  igGetID_StrStr(str_id_begin, str_id_end);
}

pragma(inline):
ImGuiID  igGetID(const void* ptr_id)
{
    return  igGetID_Ptr(ptr_id);
}

pragma(inline):
ImGuiID  igGetID(int int_id)
{
    return  igGetID_Int(int_id);
}

pragma(inline):
ImGuiID  igGetIDWithSeed(const(char)* str_id_begin, const(char)* str_id_end, ImGuiID seed)
{
    return  igGetIDWithSeed_Str(str_id_begin, str_id_end, seed);
}

pragma(inline):
ImGuiID  igGetIDWithSeed(int n, ImGuiID seed)
{
    return  igGetIDWithSeed_Int(n, seed);
}

pragma(inline):
ImGuiIO*  igGetIO()
{
    return  igGetIO_Nil();
}

pragma(inline):
ImGuiIO*  igGetIO(ImGuiContext* ctx)
{
    return  igGetIO_ContextPtr(ctx);
}

pragma(inline):
ImGuiKeyData*  igGetKeyData(ImGuiContext* ctx, ImGuiKey key)
{
    return  igGetKeyData_ContextPtr(ctx, key);
}

pragma(inline):
ImGuiKeyData*  igGetKeyData(ImGuiKey key)
{
    return  igGetKeyData_Key(key);
}

pragma(inline):
ImGuiPlatformIO*  igGetPlatformIO()
{
    return  igGetPlatformIO_Nil();
}

pragma(inline):
ImGuiPlatformIO*  igGetPlatformIO(ImGuiContext* ctx)
{
    return  igGetPlatformIO_ContextPtr(ctx);
}

pragma(inline):
int  igImAbs(int x)
{
    return  igImAbs_Int(x);
}

pragma(inline):
float  igImAbs(float x)
{
    return  igImAbs_Float(x);
}

pragma(inline):
double  igImAbs(double x)
{
    return  igImAbs_double(x);
}

pragma(inline):
float  igImFloor(float f)
{
    return  igImFloor_Float(f);
}

pragma(inline):
void  igImFloor(ImVec2* pOut, const ImVec2 v)
{
     igImFloor_Vec2(pOut, v);
}

pragma(inline):
bool  igImIsPowerOfTwo(int v)
{
    return  igImIsPowerOfTwo_Int(v);
}

pragma(inline):
bool  igImIsPowerOfTwo(ImU64 v)
{
    return  igImIsPowerOfTwo_U64(v);
}

pragma(inline):
float  igImLengthSqr(const ImVec2 lhs)
{
    return  igImLengthSqr_Vec2(lhs);
}

pragma(inline):
float  igImLengthSqr(const ImVec4 lhs)
{
    return  igImLengthSqr_Vec4(lhs);
}

pragma(inline):
void  igImLerp(ImVec2* pOut, const ImVec2 a, const ImVec2 b, float t)
{
     igImLerp_Vec2Float(pOut, a, b, t);
}

pragma(inline):
void  igImLerp(ImVec2* pOut, const ImVec2 a, const ImVec2 b, const ImVec2 t)
{
     igImLerp_Vec2Vec2(pOut, a, b, t);
}

pragma(inline):
void  igImLerp(ImVec4* pOut, const ImVec4 a, const ImVec4 b, float t)
{
     igImLerp_Vec4(pOut, a, b, t);
}

pragma(inline):
float  igImLog(float x)
{
    return  igImLog_Float(x);
}

pragma(inline):
double  igImLog(double x)
{
    return  igImLog_double(x);
}

pragma(inline):
float  igImPow(float x, float y)
{
    return  igImPow_Float(x, y);
}

pragma(inline):
double  igImPow(double x, double y)
{
    return  igImPow_double(x, y);
}

pragma(inline):
float  igImRsqrt(float x)
{
    return  igImRsqrt_Float(x);
}

pragma(inline):
double  igImRsqrt(double x)
{
    return  igImRsqrt_double(x);
}

pragma(inline):
float  igImSign(float x)
{
    return  igImSign_Float(x);
}

pragma(inline):
double  igImSign(double x)
{
    return  igImSign_double(x);
}

pragma(inline):
float  igImTrunc(float f)
{
    return  igImTrunc_Float(f);
}

pragma(inline):
void  igImTrunc(ImVec2* pOut, const ImVec2 v)
{
     igImTrunc_Vec2(pOut, v);
}

pragma(inline):
bool  igIsKeyChordPressed(ImGuiKeyChord key_chord)
{
    return  igIsKeyChordPressed_Nil(key_chord);
}

pragma(inline):
bool  igIsKeyChordPressed(ImGuiKeyChord key_chord, ImGuiInputFlags flags, ImGuiID owner_id = 0)
{
    return  igIsKeyChordPressed_InputFlags(key_chord, flags, owner_id);
}

pragma(inline):
bool  igIsKeyDown(ImGuiKey key)
{
    return  igIsKeyDown_Nil(key);
}

pragma(inline):
bool  igIsKeyDown(ImGuiKey key, ImGuiID owner_id)
{
    return  igIsKeyDown_ID(key, owner_id);
}

pragma(inline):
bool  igIsKeyPressed(ImGuiKey key, bool repeat = true)
{
    return  igIsKeyPressed_Bool(key, repeat);
}

pragma(inline):
bool  igIsKeyPressed(ImGuiKey key, ImGuiInputFlags flags, ImGuiID owner_id = 0)
{
    return  igIsKeyPressed_InputFlags(key, flags, owner_id);
}

pragma(inline):
bool  igIsKeyReleased(ImGuiKey key)
{
    return  igIsKeyReleased_Nil(key);
}

pragma(inline):
bool  igIsKeyReleased(ImGuiKey key, ImGuiID owner_id)
{
    return  igIsKeyReleased_ID(key, owner_id);
}

pragma(inline):
bool  igIsMouseClicked(ImGuiMouseButton button, bool repeat = false)
{
    return  igIsMouseClicked_Bool(button, repeat);
}

pragma(inline):
bool  igIsMouseClicked(ImGuiMouseButton button, ImGuiInputFlags flags, ImGuiID owner_id = 0)
{
    return  igIsMouseClicked_InputFlags(button, flags, owner_id);
}

pragma(inline):
bool  igIsMouseDoubleClicked(ImGuiMouseButton button)
{
    return  igIsMouseDoubleClicked_Nil(button);
}

pragma(inline):
bool  igIsMouseDoubleClicked(ImGuiMouseButton button, ImGuiID owner_id)
{
    return  igIsMouseDoubleClicked_ID(button, owner_id);
}

pragma(inline):
bool  igIsMouseDown(ImGuiMouseButton button)
{
    return  igIsMouseDown_Nil(button);
}

pragma(inline):
bool  igIsMouseDown(ImGuiMouseButton button, ImGuiID owner_id)
{
    return  igIsMouseDown_ID(button, owner_id);
}

pragma(inline):
bool  igIsMouseReleased(ImGuiMouseButton button)
{
    return  igIsMouseReleased_Nil(button);
}

pragma(inline):
bool  igIsMouseReleased(ImGuiMouseButton button, ImGuiID owner_id)
{
    return  igIsMouseReleased_ID(button, owner_id);
}

pragma(inline):
bool  igIsPopupOpen(const(char)* str_id, ImGuiPopupFlags flags = ImGuiPopupFlags.MouseButtonLeft)
{
    return  igIsPopupOpen_Str(str_id, flags);
}

pragma(inline):
bool  igIsPopupOpen(ImGuiID id, ImGuiPopupFlags popup_flags)
{
    return  igIsPopupOpen_ID(id, popup_flags);
}

pragma(inline):
bool  igIsRectVisible(const ImVec2 size)
{
    return  igIsRectVisible_Nil(size);
}

pragma(inline):
bool  igIsRectVisible(const ImVec2 rect_min, const ImVec2 rect_max)
{
    return  igIsRectVisible_Vec2(rect_min, rect_max);
}

pragma(inline):
void  igItemSize(const ImVec2 size, float text_baseline_y = -1.0f)
{
     igItemSize_Vec2(size, text_baseline_y);
}

pragma(inline):
void  igItemSize(const ImRect bb, float text_baseline_y = -1.0f)
{
     igItemSize_Rect(bb, text_baseline_y);
}

pragma(inline):
bool  igListBox(const(char)* label, int* current_item, const(char)** items, int items_count, int height_in_items = -1)
{
    return  igListBox_Str_arr(label, current_item, items, items_count, height_in_items);
}

extern(C) alias igListBox_getter = const(char)* function(void* user_data,int idx);

pragma(inline):
bool  igListBox(const(char)* label, int* current_item, igListBox_getter getter, void* user_data, int items_count, int height_in_items = -1)
{
    return  igListBox_FnStrPtr(label, current_item, getter, user_data, items_count, height_in_items);
}

pragma(inline):
void  igMarkIniSettingsDirty()
{
     igMarkIniSettingsDirty_Nil();
}

pragma(inline):
void  igMarkIniSettingsDirty(ImGuiWindow* window)
{
     igMarkIniSettingsDirty_WindowPtr(window);
}

pragma(inline):
bool  igMenuItem(const(char)* label, const(char)* shortcut = null, bool selected = false, bool enabled = true)
{
    return  igMenuItem_Bool(label, shortcut, selected, enabled);
}

pragma(inline):
bool  igMenuItem(const(char)* label, const(char)* shortcut, bool* p_selected, bool enabled = true)
{
    return  igMenuItem_BoolPtr(label, shortcut, p_selected, enabled);
}

pragma(inline):
void  igOpenPopup(const(char)* str_id, ImGuiPopupFlags popup_flags = ImGuiPopupFlags.MouseButtonLeft)
{
     igOpenPopup_Str(str_id, popup_flags);
}

pragma(inline):
void  igOpenPopup(ImGuiID id, ImGuiPopupFlags popup_flags = ImGuiPopupFlags.MouseButtonLeft)
{
     igOpenPopup_ID(id, popup_flags);
}

pragma(inline):
void  igPlotHistogram(const(char)* label, const float* values, int values_count, int values_offset = 0, const(char)* overlay_text = null, float scale_min = float.max, float scale_max = float.max, ImVec2 graph_size = ImVec2(0,0), int stride = float.sizeof)
{
     igPlotHistogram_FloatPtr(label, values, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size, stride);
}

extern(C) alias igPlotHistogram_values_getter = float function(void* data,int idx);

pragma(inline):
void  igPlotHistogram(const(char)* label, igPlotHistogram_values_getter values_getter, void* data, int values_count, int values_offset = 0, const(char)* overlay_text = null, float scale_min = float.max, float scale_max = float.max, ImVec2 graph_size = ImVec2(0,0))
{
     igPlotHistogram_FnFloatPtr(label, values_getter, data, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size);
}

pragma(inline):
void  igPlotLines(const(char)* label, const float* values, int values_count, int values_offset = 0, const(char)* overlay_text = null, float scale_min = float.max, float scale_max = float.max, ImVec2 graph_size = ImVec2(0,0), int stride = float.sizeof)
{
     igPlotLines_FloatPtr(label, values, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size, stride);
}

extern(C) alias igPlotLines_values_getter = float function(void* data,int idx);

pragma(inline):
void  igPlotLines(const(char)* label, igPlotLines_values_getter values_getter, void* data, int values_count, int values_offset = 0, const(char)* overlay_text = null, float scale_min = float.max, float scale_max = float.max, ImVec2 graph_size = ImVec2(0,0))
{
     igPlotLines_FnFloatPtr(label, values_getter, data, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size);
}

pragma(inline):
void  igPushID(const(char)* str_id)
{
     igPushID_Str(str_id);
}

pragma(inline):
void  igPushID(const(char)* str_id_begin, const(char)* str_id_end)
{
     igPushID_StrStr(str_id_begin, str_id_end);
}

pragma(inline):
void  igPushID(const void* ptr_id)
{
     igPushID_Ptr(ptr_id);
}

pragma(inline):
void  igPushID(int int_id)
{
     igPushID_Int(int_id);
}

pragma(inline):
void  igPushStyleColor(ImGuiCol idx, ImU32 col)
{
     igPushStyleColor_U32(idx, col);
}

pragma(inline):
void  igPushStyleColor(ImGuiCol idx, const ImVec4 col)
{
     igPushStyleColor_Vec4(idx, col);
}

pragma(inline):
void  igPushStyleVar(ImGuiStyleVar idx, float val)
{
     igPushStyleVar_Float(idx, val);
}

pragma(inline):
void  igPushStyleVar(ImGuiStyleVar idx, const ImVec2 val)
{
     igPushStyleVar_Vec2(idx, val);
}

pragma(inline):
bool  igRadioButton(const(char)* label, bool active)
{
    return  igRadioButton_Bool(label, active);
}

pragma(inline):
bool  igRadioButton(const(char)* label, int* v, int v_button)
{
    return  igRadioButton_IntPtr(label, v, v_button);
}

pragma(inline):
bool  igSelectable(const(char)* label, bool selected = false, ImGuiSelectableFlags flags = ImGuiSelectableFlags.None, const ImVec2 size = ImVec2(0,0))
{
    return  igSelectable_Bool(label, selected, flags, size);
}

pragma(inline):
bool  igSelectable(const(char)* label, bool* p_selected, ImGuiSelectableFlags flags = ImGuiSelectableFlags.None, const ImVec2 size = ImVec2(0,0))
{
    return  igSelectable_BoolPtr(label, p_selected, flags, size);
}

pragma(inline):
void  igSetItemKeyOwner(ImGuiKey key)
{
     igSetItemKeyOwner_Nil(key);
}

pragma(inline):
void  igSetItemKeyOwner(ImGuiKey key, ImGuiInputFlags flags)
{
     igSetItemKeyOwner_InputFlags(key, flags);
}

pragma(inline):
void  igSetScrollFromPosX(float local_x, float center_x_ratio = 0.5f)
{
     igSetScrollFromPosX_Float(local_x, center_x_ratio);
}

pragma(inline):
void  igSetScrollFromPosX(ImGuiWindow* window, float local_x, float center_x_ratio)
{
     igSetScrollFromPosX_WindowPtr(window, local_x, center_x_ratio);
}

pragma(inline):
void  igSetScrollFromPosY(float local_y, float center_y_ratio = 0.5f)
{
     igSetScrollFromPosY_Float(local_y, center_y_ratio);
}

pragma(inline):
void  igSetScrollFromPosY(ImGuiWindow* window, float local_y, float center_y_ratio)
{
     igSetScrollFromPosY_WindowPtr(window, local_y, center_y_ratio);
}

pragma(inline):
void  igSetScrollX(float scroll_x)
{
     igSetScrollX_Float(scroll_x);
}

pragma(inline):
void  igSetScrollX(ImGuiWindow* window, float scroll_x)
{
     igSetScrollX_WindowPtr(window, scroll_x);
}

pragma(inline):
void  igSetScrollY(float scroll_y)
{
     igSetScrollY_Float(scroll_y);
}

pragma(inline):
void  igSetScrollY(ImGuiWindow* window, float scroll_y)
{
     igSetScrollY_WindowPtr(window, scroll_y);
}

pragma(inline):
void  igSetWindowCollapsed(bool collapsed, ImGuiCond cond = ImGuiCond.None)
{
     igSetWindowCollapsed_Bool(collapsed, cond);
}

pragma(inline):
void  igSetWindowCollapsed(const(char)* name, bool collapsed, ImGuiCond cond = ImGuiCond.None)
{
     igSetWindowCollapsed_Str(name, collapsed, cond);
}

pragma(inline):
void  igSetWindowCollapsed(ImGuiWindow* window, bool collapsed, ImGuiCond cond = ImGuiCond.None)
{
     igSetWindowCollapsed_WindowPtr(window, collapsed, cond);
}

pragma(inline):
void  igSetWindowFocus()
{
     igSetWindowFocus_Nil();
}

pragma(inline):
void  igSetWindowFocus(const(char)* name)
{
     igSetWindowFocus_Str(name);
}

pragma(inline):
void  igSetWindowPos(const ImVec2 pos, ImGuiCond cond = ImGuiCond.None)
{
     igSetWindowPos_Vec2(pos, cond);
}

pragma(inline):
void  igSetWindowPos(const(char)* name, const ImVec2 pos, ImGuiCond cond = ImGuiCond.None)
{
     igSetWindowPos_Str(name, pos, cond);
}

pragma(inline):
void  igSetWindowPos(ImGuiWindow* window, const ImVec2 pos, ImGuiCond cond = ImGuiCond.None)
{
     igSetWindowPos_WindowPtr(window, pos, cond);
}

pragma(inline):
void  igSetWindowSize(const ImVec2 size, ImGuiCond cond = ImGuiCond.None)
{
     igSetWindowSize_Vec2(size, cond);
}

pragma(inline):
void  igSetWindowSize(const(char)* name, const ImVec2 size, ImGuiCond cond = ImGuiCond.None)
{
     igSetWindowSize_Str(name, size, cond);
}

pragma(inline):
void  igSetWindowSize(ImGuiWindow* window, const ImVec2 size, ImGuiCond cond = ImGuiCond.None)
{
     igSetWindowSize_WindowPtr(window, size, cond);
}

pragma(inline):
bool  igShortcut(ImGuiKeyChord key_chord, ImGuiInputFlags flags = ImGuiInputFlags.None)
{
    return  igShortcut_Nil(key_chord, flags);
}

pragma(inline):
bool  igShortcut(ImGuiKeyChord key_chord, ImGuiInputFlags flags, ImGuiID owner_id)
{
    return  igShortcut_ID(key_chord, flags, owner_id);
}

pragma(inline):
void  igTabBarQueueFocus(ImGuiTabBar* tab_bar, ImGuiTabItem* tab)
{
     igTabBarQueueFocus_TabItemPtr(tab_bar, tab);
}

pragma(inline):
void  igTabBarQueueFocus(ImGuiTabBar* tab_bar, const(char)* tab_name)
{
     igTabBarQueueFocus_Str(tab_bar, tab_name);
}

pragma(inline):
void  igTabItemCalcSize(ImVec2* pOut, const(char)* label, bool has_close_button_or_unsaved_marker)
{
     igTabItemCalcSize_Str(pOut, label, has_close_button_or_unsaved_marker);
}

pragma(inline):
void  igTabItemCalcSize(ImVec2* pOut, ImGuiWindow* window)
{
     igTabItemCalcSize_WindowPtr(pOut, window);
}

pragma(inline):
void  igTableGcCompactTransientBuffers(ImGuiTable* table)
{
     igTableGcCompactTransientBuffers_TablePtr(table);
}

pragma(inline):
void  igTableGcCompactTransientBuffers(ImGuiTableTempData* table)
{
     igTableGcCompactTransientBuffers_TableTempDataPtr(table);
}

pragma(inline):
const(char)*  igTableGetColumnName(int column_n = -1)
{
    return  igTableGetColumnName_Int(column_n);
}

pragma(inline):
const(char)*  igTableGetColumnName(const ImGuiTable* table, int column_n)
{
    return  igTableGetColumnName_TablePtr(table, column_n);
}

pragma(inline):
bool  igTreeNode(const(char)* label)
{
    return  igTreeNode_Str(label);
}

pragma(inline):
bool  igTreeNode(const(char)* str_id, const(char)* fmt, ...)
{
    return  igTreeNode_StrStr(str_id, fmt);
}

pragma(inline):
bool  igTreeNode(const void* ptr_id, const(char)* fmt, ...)
{
    return  igTreeNode_Ptr(ptr_id, fmt);
}

pragma(inline):
bool  igTreeNodeEx(const(char)* label, ImGuiTreeNodeFlags flags = ImGuiTreeNodeFlags.None)
{
    return  igTreeNodeEx_Str(label, flags);
}

pragma(inline):
bool  igTreeNodeEx(const(char)* str_id, ImGuiTreeNodeFlags flags, const(char)* fmt, ...)
{
    return  igTreeNodeEx_StrStr(str_id, flags, fmt);
}

pragma(inline):
bool  igTreeNodeEx(const void* ptr_id, ImGuiTreeNodeFlags flags, const(char)* fmt, ...)
{
    return  igTreeNodeEx_Ptr(ptr_id, flags, fmt);
}

pragma(inline):
bool  igTreeNodeExV(const(char)* str_id, ImGuiTreeNodeFlags flags, const(char)* fmt, va_list args)
{
    return  igTreeNodeExV_Str(str_id, flags, fmt, args);
}

pragma(inline):
bool  igTreeNodeExV(const void* ptr_id, ImGuiTreeNodeFlags flags, const(char)* fmt, va_list args)
{
    return  igTreeNodeExV_Ptr(ptr_id, flags, fmt, args);
}

pragma(inline):
bool  igTreeNodeV(const(char)* str_id, const(char)* fmt, va_list args)
{
    return  igTreeNodeV_Str(str_id, fmt, args);
}

pragma(inline):
bool  igTreeNodeV(const void* ptr_id, const(char)* fmt, va_list args)
{
    return  igTreeNodeV_Ptr(ptr_id, fmt, args);
}

pragma(inline):
void  igTreePush(const(char)* str_id)
{
     igTreePush_Str(str_id);
}

pragma(inline):
void  igTreePush(const void* ptr_id)
{
     igTreePush_Ptr(ptr_id);
}

pragma(inline):
void  igValue(const(char)* prefix, bool b)
{
     igValue_Bool(prefix, b);
}

pragma(inline):
void  igValue(const(char)* prefix, int v)
{
     igValue_Int(prefix, v);
}

pragma(inline):
void  igValue(const(char)* prefix, uint v)
{
     igValue_Uint(prefix, v);
}

pragma(inline):
void  igValue(const(char)* prefix, float v, const(char)* float_format = null)
{
     igValue_Float(prefix, v, float_format);
}

