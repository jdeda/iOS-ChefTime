import ComposableArchitecture

extension AlertState where Action == RecipeReducer.Action.AlertAction {
  static let deletePhotos = Self(
    title: {
      TextState("Delete Photos")
    },
    actions: {
      ButtonState(
        role: .destructive,
        action: .send(.confirmDeleteSectionButtonTapped(.photos), animation: .default)
      ){
        TextState("Delete")
      }
      ButtonState(role: .cancel) {
        TextState("Cancel")
      }
    },
    message: {
      TextState("Are you sure you want to delete this section? All subsections will be deleted.")
    }
  )
  static let deleteAbout = Self(
    title: {
      TextState("Delete About")
    },
    actions: {
      ButtonState(
        role: .destructive,
        action: .send(.confirmDeleteSectionButtonTapped(.about), animation: .default)
      ){
        TextState("Delete")
      }
      ButtonState(role: .cancel) {
        TextState("Cancel")
      }
    },
    message: {
      TextState("Are you sure you want to delete this section? All subsections will be deleted.")
    }
  )
  static let deleteIngredients = Self(
    title: {
      TextState("Delete Ingredients")
    },
    actions: {
      ButtonState(
        role: .destructive,
        action: .send(.confirmDeleteSectionButtonTapped(.ingredients), animation: .default)
      ){
        TextState("Delete")
      }
      ButtonState(role: .cancel) {
        TextState("Cancel")
      }
    },
    message: {
      TextState("Are you sure you want to delete this section? All subsections will be deleted.")
    }
  )
  static let deleteSteps = Self(
    title: {
      TextState("Delete Steps")
    },
    actions: {
      ButtonState(
        role: .destructive,
        action: .send(.confirmDeleteSectionButtonTapped(.steps), animation: .default)
      ){
        TextState("Delete")
      }
      ButtonState(role: .cancel) {
        TextState("Cancel")
      }
    },
    message: {
      TextState("Are you sure you want to delete this section? All subsections will be deleted.")
    }
  )
}
