extends Control
class_name Root_gui

# 递归设置子节点的 process 状态
func set_children_process(node: Node, enabled: bool):
	if enabled:
		node.process_mode = Node.PROCESS_MODE_INHERIT
	elif not enabled:
		node.process_mode = Node.PROCESS_MODE_DISABLED
	for child in node.get_children():
		set_children_process(child, enabled)  # 递归处理子节点

# 隐藏时禁用所有子节点
func GUI_hide():
	self.visible = false
	set_children_process(self, false)

# 显示时启用所有子节点
func GUI_show():
	self.visible = true
	set_children_process(self, true)
