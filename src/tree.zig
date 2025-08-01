const std = @import("std");

const TreeErrors = error{
    NoAllocatorPresent
};

pub fn TreeNode(comptime OuterType: type) type {
    return struct {
        objectPtr: ?*OuterType = null,
        allocator: ?std.mem.Allocator = null,
        parent: ?*TreeNode(OuterType) = null,
        children: ?std.ArrayList(*TreeNode(OuterType)) = null,
        indexInParent: usize = undefined, //TODO not used yet

        pub fn AddChild(self: *TreeNode(OuterType), newChild: *TreeNode(OuterType)) !void
        {
            std.debug.print("{?}\n",.{self.children});
            if (self.children) |*list|
            {
                newChild.*.allocator = self.*.allocator;
                newChild.*.parent = self;
                try list.append(newChild);
            }
            else 
            {
                try self.SetUpChildArray();
                newChild.*.allocator = self.*.allocator;
                newChild.*.parent = self;
                try self.children.?.append(newChild);
            }

        }

        fn SetUpChildArray(self: *TreeNode(OuterType)) !void
        {
            if (self.allocator) |allocator|
            {
                self.children = std.ArrayList(*TreeNode(OuterType)).init(allocator);
            }
            else
            {
                return TreeErrors.NoAllocatorPresent;
            }
        }

        pub fn Deinit(self: *TreeNode(OuterType)) !void
        {
            if (self.allocator) |allocator|
            {

                //If this tree node had any children
                if (self.children) |children|
                {
                    //tell them to Deinit first
                    for (children.items) |child|
                    {
                        try child.*.Deinit();
                    }

                    //then Deinit the children array
                    children.deinit();
                }

                //then destroy yourself
                allocator.destroy(self);
            }
            else 
            {
                return TreeErrors.NoAllocatorPresent;
            }
        }
    };
}