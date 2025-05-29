## 直接操作二进制编码
extends Object
class_name Manipulating_Binary

# 将 32 位整型转换为 4 字节的 PackedByteArray（小端序）
func int_to_bytes(value: int) -> PackedByteArray:
	var bytes = PackedByteArray()
	# 按小端序（低位在前）拆分字节
	bytes.append((value >> 0) & 0xFF)  # 最低位字节
	bytes.append((value >> 8) & 0xFF)
	bytes.append((value >> 16) & 0xFF)
	bytes.append((value >> 24) & 0xFF) # 最高位字节
	return bytes

# 将 4 字节转换为浮点数
func bytes_to_float(bytes: PackedByteArray) -> float:
	# 创建 PackedByteArray 并解码为浮点数
	var buffer = PackedByteArray(bytes)
	return buffer.decode_float(0)

# 将 32 位整型转换为浮点数（直接二进制拷贝）
func int_to_float(value: int) -> float:
	var bytes = int_to_bytes(value)
	return bytes_to_float(bytes)
