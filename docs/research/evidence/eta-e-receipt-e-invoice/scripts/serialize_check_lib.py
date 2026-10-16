"""Shared serialiser (same logic as serialize_check.py) so uuid_check.py can import it."""
def ser(v):
    if isinstance(v, dict):
        out = []
        for k, x in v.items():
            if isinstance(x, list):
                out.append('"%s"' % k.upper())
                for el in x:
                    out.append('"%s"' % k.upper()); out.append(ser(el))
            else:
                out.append('"%s"' % k.upper()); out.append(ser(x))
        return "".join(out)
    if v is None: return '""'
    return '"%s"' % v
