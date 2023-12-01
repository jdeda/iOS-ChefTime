import IdentifiedCollections

extension IdentifiedArrayOf where Element: Identifiable {
  func map<B>(_ transform: (Element) -> B) -> IdentifiedArrayOf<B> where B: Identifiable {
    .init(uniqueElements: self.elements.map(transform))
  }
}

extension IdentifiedArrayOf where Element: Identifiable, Element.ID == ID {
  func intersectionByID(_ other: IdentifiedArrayOf<Element>) -> IdentifiedArrayOf<Element> {
    let ids = self.ids.intersection(other.ids)
    return self.filter { ids.contains($0.id) }
  }
}

extension IdentifiedArrayOf where Element: Identifiable, Element.ID == ID {
  func symmetricDifferenceByID(_ other: IdentifiedArrayOf<Element>) -> IdentifiedArrayOf<Element> {
    let ids = self.ids.symmetricDifference(other.ids)
    return self.filter { ids.contains($0.id) }
  }
}

