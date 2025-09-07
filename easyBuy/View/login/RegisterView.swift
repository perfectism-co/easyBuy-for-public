//
//  RegisterView.swift
//  MyAuthBookApp
//
//  
//
import SwiftUI


struct RegisterView: View {
    @StateObject var vm: AuthViewModel
    

    var body: some View {
        
        VStack(spacing: 20) {
            
            EmailField(text: $vm.email)
    
            PasswordField(password: $vm.password)

            Text("By tapping Done, you agree to the privacy policy and terms of service.")
                .font(.footnote)
                .foregroundColor(Color.gray)
            
            PrimaryFilledButton(title: "Register") {
                Task { await vm.register() }
            }
            .padding(.top, 20)
            
//            if let err = vm.message {
//                Text(err).foregroundColor(.red)
//            }
        }
        .padding()
        .navigationBarHidden(true)
    }
}



#Preview {
   
   RegisterView(vm: AuthViewModel())
    .environmentObject(AuthViewModel.preview())
    .environmentObject(ShippingViewModel())
    .environmentObject(CouponViewModel())
    .environmentObject(ProductViewModel())
    
}
