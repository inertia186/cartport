"""Keep native test carts within PICO-8's token limit without changing called code."""
import re


def check_cart(source, fixture):
    lua, assets = source.split("__gfx__", 1)
    # Cart functions are top-level, column-zero declarations. Keep each complete
    # body and every function it names, including callbacks stored in tables.
    parts = re.split(r"(?=^function \w+\()", lua, flags=re.M)
    functions = {re.match(r"function (\w+)", part)[1]: part for part in parts[1:]}
    roots = parts[0] + fixture
    roots = re.sub(r"\b_(init|draw|update60)=nil\b", "", roots)
    needed = set()
    pending = set(re.findall(r"\b\w+\b", roots)) & functions.keys()
    while pending:
        name = pending.pop()
        needed.add(name)
        pending |= (set(re.findall(r"\b\w+\b", functions[name])) & functions.keys()) - needed
    return parts[0] + "".join(body for name, body in functions.items() if name in needed) + fixture + "\n__gfx__" + assets
