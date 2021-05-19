// Copyright (c) 2021 ffi_tool authors.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
// OR OTHER DEALINGS IN THE SOFTWARE.

import 'package:meta/meta.dart';

/// Lowercase definition names to mappings.
const _types = <String, _Type>{
  '*void': _Type(ffi: 'ffi.Pointer', dart: 'ffi.Pointer'),
  'void': _Type(ffi: 'ffi.Void', dart: 'void'),

  'intptr': _Type(ffi: 'ffi.IntPtr', dart: 'int'),

  // For convenience
  'size_t': _Type(ffi: 'ffi.IntPtr', dart: 'int'),

  'char': _Type(ffi: 'ffi.Uint8', dart: 'int'),
  'int8': _Type(ffi: 'ffi.Int8', dart: 'int'),
  'int16': _Type(ffi: 'ffi.Int16', dart: 'int'),
  'int32': _Type(ffi: 'ffi.Int32', dart: 'int'),
  'int64': _Type(ffi: 'ffi.Int64', dart: 'int'),
  'uint8': _Type(ffi: 'ffi.Uint8', dart: 'int'),
  'uint16': _Type(ffi: 'ffi.Uint16', dart: 'int'),
  'uint32': _Type(ffi: 'ffi.Uint32', dart: 'int'),
  'uint64': _Type(ffi: 'ffi.Uint64', dart: 'int'),
  'float': _Type(ffi: 'ffi.Float', dart: 'double'),
  'double': _Type(ffi: 'ffi.Double', dart: 'double'),
  'float32': _Type(ffi: 'ffi.Float', dart: 'double'),
  'float64': _Type(ffi: 'ffi.Double', dart: 'double'),
};

class DartSourceWriter {
  String libraryName;
  String partOf;
  String preamble;
  final Set<ImportedUri> imports = {};
  final Set<String> parts = {};
  final StringBuffer _sb = StringBuffer();

  /// Returns Dart C type for the description type.
  ///
  /// Examples:
  ///   * 'Int32' --> 'Int32'
  ///   * '*CFString' --> 'Pointer<CFString>'
  ///   * '*void' --> 'Pointer'
  ///   * 'void' --> 'Void'
  String getCType(String name) {
    if (name == null) {
      throw ArgumentError.value(name);
    }
    final type = _types[name.toLowerCase()];
    if (type != null) {
      final importUri = type.importInfo;
      if (importUri != null) {
        imports.add(importUri);
      }
      return type.ffi;
    }
    if (name.startsWith('*')) {
      return 'ffi.Pointer<${getCType(name.substring(1))}>';
    }
    return name;
  }

  /// Converts description type to Dart type.
  ///
  /// Examples:
  ///   * 'Int32' --> 'int'
  ///   * 'Int64' --> 'int'
  ///   * '*CFString' --> 'Pointer<CFString>'
  String getDartType(String name) {
    if (name == null) {
      throw ArgumentError.notNull();
    }
    final type = _types[name.toLowerCase()];
    if (type != null) {
      final importUri = type.importInfo;
      if (importUri != null) {
        imports.add(importUri);
      }
      return type.dart;
    }
    if (name.startsWith('*')) {
      return 'ffi.Pointer<${getCType(name.substring(1))}>';
    }
    return name;
  }

  /// Returns Dart C type for the description type.
  ///
  /// Examples:
  ///   * 'Int32' --> 'Int32'
  ///   * '*CFString' --> 'Pointer<CFString>'
  ///   * '*void' --> 'Pointer'
  ///   * 'void' --> 'Void'
  String getPropertyAnnotationType(String name) {
    if (name.startsWith('*')) {
      return 'ffi.Pointer';
    }
    final type = _types[name.toLowerCase()];
    if (type != null) {
      return type.ffi;
    }
    return null;
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(preamble);
    sb.write('\n');

    // Library name
    if (libraryName != null) {
      sb.write('\n');
      sb.write('library $libraryName;\n');
    }

    // Part of
    if (partOf != null) {
      sb.write('\n');
      sb.write('partOf $partOf;\n');
    }

    // Imports
    if (imports.isNotEmpty) {
      sb.write('\n');
      for (var importInfo in imports.toList()..sort()) {
        sb.write("import '${importInfo.uri}'");
        final prefix = importInfo.prefix;
        final show = importInfo.show;
        final hide = importInfo.hide;
        if (prefix != null) {
          sb.write(' as $prefix');
        }
        if (show != null) {
          sb.write(' show $show');
        }
        if (hide != null) {
          sb.write(' hide $hide');
        }
        sb.write(';\n');
      }
    }

    // Parts
    if (parts.isNotEmpty) {
      for (var part in parts) {
        sb.write("part '$part';\n");
      }
    }

    // Content
    sb.write('\n');
    sb.write(_sb.toString());
    return sb.toString();
  }

  void write(Object obj) {
    _sb.write(obj);
  }

  void writeAll(Iterable objects, [String separator = '']) {
    _sb.writeAll(objects, separator);
  }
}

/// Describes an imported Dart package.
class ImportedUri implements Comparable<ImportedUri> {
  final String uri;
  final String prefix;
  final String show;
  final String hide;

  const ImportedUri(this.uri, {this.prefix, this.show, this.hide});

  @override
  int get hashCode => uri.hashCode;

  @override
  bool operator ==(other) =>
      other is ImportedUri && uri == other.uri && prefix == other.prefix;

  @override
  int compareTo(ImportedUri other) {
    {
      final r = uri.compareTo(other.uri);
      if (r != 0) {
        return r;
      }
    }
    return (prefix ?? '').compareTo(other.prefix ?? '');
  }
}

class _Type {
  final String ffi;
  final String dart;
  final ImportedUri importInfo;
  const _Type({@required this.ffi, @required this.dart, this.importInfo});
}
