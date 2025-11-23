python3 -c "
import json

with open('result_minimal/generic_stat.json', 'r') as f:
    data = json.load(f)

# 查找包含 num_cells_by_type 的键
def find_cells(obj, path=''):
    if isinstance(obj, dict):
        if 'num_cells_by_type' in obj:
            cells = obj['num_cells_by_type']
            total = sum(cells.values())
            print(f'路径: {path}')
            print(f'总 instances 数量: {total:,}')
            print(f'不同类型的 cell 数量: {len(cells)}')
            return
        for key, value in obj.items():
            find_cells(value, f'{path}.{key}' if path else key)

find_cells(data)
"
