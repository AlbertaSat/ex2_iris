def unsigned_to_vhdl(u, width=12):
    return f'to_unsigned({u}, {width})'


def uarray_to_vhdl(uarray, width=12):
    return '(' + ', '.join(f'{i} => {unsigned_to_vhdl(u, width)}'
                           for i, u in enumerate(uarray)) + ')'


def uarray2d_to_vhdl(uarray2d, width=12, indent=''):
    indent2 = indent + '    '
    return '(\n' + ',\n'.join(f'{indent2}{i} => {uarray_to_vhdl(uarray, width)}'
                          for i, uarray in enumerate(uarray2d)) + f'\n{indent})'


def uarray3d_to_vhdl(uarray3d, width=12, indent=''):
    indent2 = indent + '    '
    return '(\n' + ',\n'.join(f'{indent2}{i} => {uarray2d_to_vhdl(uarray2d, width, indent2)}'
                              for i, uarray2d in enumerate(uarray3d)) + f'\n{indent})'


def logic_vector_to_vhdl(i, width=12):
    # See https://stackoverflow.com/questions/699866/python-int-to-binary-string
    return '"' + bin(i)[2:].zfill(width) + '"'


def logic_vector2d_to_vhdl(v, width=12):
    return '(' + ', '.join(f'{i} => {logic_vector_to_vhdl(elem, width)}'
                              for i, elem in enumerate(v)) + ')'


def logic_vector3d_to_vhdl(v, width=12, indent=''):
    indent2 = indent + '    '
    return '(\n' + ',\n'.join(f'{indent2}{i} => {logic_vector2d_to_vhdl(elem, width)}'
                              for i, elem in enumerate(v)) + f'\n{indent})'
