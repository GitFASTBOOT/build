package jvm;

/** Bar class. The class for testing code assist within the same build module. */
class Bar<K extends Number, V extends Number> {
  Bar() {
    foo(new Foo());
  }

  void foo(Foo f) {}

  void foo(Object o) {}

  void bar(Foo f) {}

  void baz(Object o) {}
}