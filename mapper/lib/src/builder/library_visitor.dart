import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor2.dart';

import '../model/annotations.dart';

class LibraryVisitor extends RecursiveElementVisitor2<void> {
  Map<int, ClassElement> visitedPublicClassElements = {};
  Map<int, ClassElement> visitedPublicAnnotatedClassElements = {};
  Map<int, EnumElement> visitedPublicAnnotatedEnumElements = {};
  Map<String, LibraryElement?> visitedLibraries = {};

  final _annotationClassName = jsonSerializable.runtimeType.toString();
  String? packageName;

  LibraryVisitor(this.packageName);

  List<InterfaceElement> get visitedPublicAnnotatedElements {
    return [
      ...visitedPublicAnnotatedClassElements.values,
      ...visitedPublicAnnotatedEnumElements.values,
    ];
  }

  bool _isJsonSerializable(Element element) {
    return element.metadata.annotations.any((meta) {
      final value = meta.computeConstantValue();
      return value?.type?.getDisplayString() == _annotationClassName;
    });
  }

  @override
  void visitClassElement(ClassElement element) {
    if (!element.isPrivate &&
        !visitedPublicClassElements.containsKey(element.id)) {
      visitedPublicClassElements.putIfAbsent(element.id, () => element);
      if (_isJsonSerializable(element)) {
        visitedPublicAnnotatedClassElements.putIfAbsent(
          element.id,
          () => element,
        );
      }
    }
    super.visitClassElement(element);
  }

  @override
  void visitEnumElement(EnumElement element) {
    if (!element.isPrivate &&
        !visitedPublicAnnotatedEnumElements.containsKey(element.id)) {
      visitedPublicAnnotatedEnumElements.putIfAbsent(element.id, () => element);
      if (_isJsonSerializable(element)) {
        visitedPublicAnnotatedEnumElements.putIfAbsent(
          element.id,
          () => element,
        );
      }
    }
    super.visitEnumElement(element);
  }

  @override
  void visitLibraryElement(LibraryElement element) {
    for (final fragment in element.fragments) {
      for (final export in fragment.libraryExports) {
        _visitLibrary(export.exportedLibrary);
      }
      for (final import in fragment.libraryImports) {
        _visitLibrary(import.importedLibrary);
      }
    }
    super.visitLibraryElement(element);
  }

  void _visitLibrary(LibraryElement? element) {
    final identifier = element?.identifier;
    if (identifier != null &&
        !visitedLibraries.containsKey(identifier) &&
        (identifier.startsWith('asset:') ||
            identifier.startsWith(packageName!))) {
      visitedLibraries.putIfAbsent(identifier, () => element);
      element!.accept(this);
    }
  }

  void visitLibrary(LibraryElement? element) => _visitLibrary(element);
}
