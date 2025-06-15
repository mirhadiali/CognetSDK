
import SwiftUI

struct InputTextViewWithIcon: View {
    @Binding var text: String
    var placeholder: String
    var color: Color = ThemeManager.color(.text)
    var placeholderColor: Color = ThemeManager.color(.textPlaceHolder)
    var bgColor: Color = ThemeManager.color(.primary)
    
    var limit:Bool = false
    
    var keyboard:UIKeyboardType = .emailAddress
    
    var body: some View {
        ZStack{
            HStack{
                if #available(iOS 15, *) {
                    TextField("",
                              text: $text,
                              prompt: Text(placeholder).foregroundColor(placeholderColor)
                    ).keyboardType(keyboard)
                        .font(FontManager.customFont(.regular, size: .medium))
                        .foregroundColor(color)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: text, perform: { newValue in
                            if limit == true{
                                if newValue.count > 10 {
                                    // If the new value exceeds 10 characters, trim the string to keep only the first 10 characters
                                    text = String(newValue.prefix(10))
                                }
                            }
                        })
                    
                }
                else{
                    TextField("",
                              text: $text
                    )
                    .foregroundColor(color)
                    .font(FontManager.customFont(.regular, size: .medium))
                    .autocapitalization(.none)
                    .keyboardType(keyboard)
                    .disableAutocorrection(true)
                    .onChange(of: text) { newValue in
                        if limit == true{
                            if newValue.count > 10 {
                                // If the new value exceeds 10 characters, trim the string to keep only the first 10 characters
                                text = String(newValue.prefix(10))
                            }
                        }
                    }
                    
                    
                }
                
            }
            .padding()
        }
        .background(Rectangle().fill(bgColor).cornerRadius(15))
    }
}

struct PasswordInputTextView: View {
    
    @Binding var text: String
    @State private var isPasswordVisible: Bool = false
    var placeHolder: String = "Password"
    var color: Color = ThemeManager.color(.text)
    var bgColor: Color = ThemeManager.color(.secondary)
    var placeholderColor: Color = ThemeManager.color(.textPlaceHolder)
    
    var body: some View {
        ZStack{
            HStack{
                if isPasswordVisible {
                    TextField(placeHolder, text: $text)
                        .font(FontManager.customFont(.regular, size: .medium))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .foregroundColor(color)
                } else {
                    if #available(iOS 15, *) {
                        SecureField("", text: $text, prompt: Text(placeHolder).foregroundColor(placeholderColor))
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .privacySensitive()
                    } else {
                        SecureField(placeHolder, text: $text)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .foregroundColor(color)
                    }
                }
                
                Button(action: {
                    // Toggle the password visibility state
                    self.isPasswordVisible.toggle()
                }) {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(color)
                        .padding(.trailing, 10)
                }
            }
            .padding()
        }
        .background(Rectangle().fill(bgColor).cornerRadius(15))
    }
}
#if DEBUG
#Preview {
    PreviewWrapper()
}
struct PreviewWrapper: View {
    @State private var text: String = ""
    var body: some View {
        InputTextViewWithIcon(text: $text, placeholder: "Email")
    }
}
#endif
