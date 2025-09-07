//
//  LoginView.swift
//  MyAuthBookApp
//
//  
//

import SwiftUI


struct LoginView: View {
    @StateObject var vm: AuthViewModel
    
    var body: some View {
       
            VStack(spacing: 20) {
                EmailField(text: $vm.email)
                
                PasswordField(password: $vm.password)
                
                PrimaryFilledButton(title: "Login") {
                    Task { await vm.login() }
                }
                
//                if let err = vm.message {
//                    Text(err).foregroundColor(.red)
//                }
            }
            .padding()
            .navigationBarHidden(true)
    }
}


#Preview {

  LoginView(vm: AuthViewModel())    
    .environmentObject(AuthViewModel.preview())
    .environmentObject(ShippingViewModel())
    .environmentObject(CouponViewModel())
    .environmentObject(ProductViewModel())
    
    
}



