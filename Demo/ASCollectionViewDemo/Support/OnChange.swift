import SwiftUI

extension View
{
	func onChange<V: Equatable>(of value: V, perform action: @escaping (V) -> Void) -> some View
	{
		OnChange(content: self, value: value, perform: action)
	}
}

// `View.onChange(of:perform:)` is only available on iOS 14.0+
// https://developer.apple.com/documentation/swiftui/view/onchange(of:perform:)
private struct OnChange<Content: View, V: Equatable>: View
{
	private let content: Content
	private let current: V
	private let action: (V) -> Void

	@State private var state: ValueState<V>

	init(content: Content, value: V, perform action: @escaping (V) -> Void)
	{
		self.content = content
		current = value
		self.action = action
		_state = .init(initialValue: ValueState(value))
	}

	var body: some View
	{
		if state.didChange(current)
		{
			DispatchQueue.main.async
			{
				self.action(self.current)
			}
		}
		return content
	}
}

private final class ValueState<V: Equatable>
{
	private var current: V

	init(_ value: V)
	{
		current = value
	}

	func didChange(_ new: V) -> Bool
	{
		guard new != current else { return false }
		current = new
		return true
	}
}
