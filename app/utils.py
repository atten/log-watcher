import re


def str_to_int(s: str) -> int:
    if s is None:
        return 0
    try:
        return int(s)
    except ValueError:
        nums = re.findall(r'\d+', s)
        return int(nums[0]) if len(nums) else 0
