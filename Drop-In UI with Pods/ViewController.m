//
//  ViewController.m
//  Drop-In UI with Pods
//
//  Created by Orcun on 11/01/2016.
//  Copyright © 2016 Orcun. All rights reserved.
//

#import "ViewController.h"
#import "BraintreeCore.h"
#import "BraintreeUI.h"


@interface ViewController () <BTDropInViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *buyButton;

@property (nonatomic, strong) BTAPIClient *braintreeClient;

@end

@implementation ViewController

NSString *resultCheck;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // TODO: Switch this URL to your own authenticated API
    NSURL *clientTokenURL = [NSURL URLWithString:@"http://orcodevbox.co.uk/BTOrcun/tokenGen.php"];
    NSMutableURLRequest *clientTokenRequest = [NSMutableURLRequest requestWithURL:clientTokenURL];
    [clientTokenRequest setValue:@"text/plain" forHTTPHeaderField:@"Accept"];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:clientTokenRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        // TODO: Handle errors
        NSString *clientToken = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        // Log the client token to confirm that it is returned from the server
        NSLog(@"%@",clientToken);
        
        self.braintreeClient = [[BTAPIClient alloc] initWithAuthorization:clientToken];
        // As an example, you may wish to present our Drop-in UI at this point.
        // Continue to the next section to learn more...
    }] resume];
    
    
}


- (IBAction)buyAction:(id)sender {
    // Create a BTDropInViewController
    BTDropInViewController *dropInViewController = [[BTDropInViewController alloc]
                                                    initWithAPIClient:self.braintreeClient];
    dropInViewController.delegate = self;
    
    // This is where you might want to customize your view controller (see below)
    
    // The way you present your BTDropInViewController instance is up to you.
    // In this example, we wrap it in a new, modally-presented navigation controller:
    UIBarButtonItem *item = [[UIBarButtonItem alloc]
                             initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                             target:self
                             action:@selector(userDidCancelPayment)];
    dropInViewController.navigationItem.leftBarButtonItem = item;
    UINavigationController *navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:dropInViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
    
}

- (void)userDidCancelPayment {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)dropInViewController:(BTDropInViewController *)viewController
  didSucceedWithTokenization:(BTPaymentMethodNonce *)paymentMethodNonce {
    NSLog(@"Nonce received: %@",paymentMethodNonce.nonce);
    NSLog(@"Card type: %@",paymentMethodNonce.type);
    // Send payment method nonce to your server for processing
    [self postNonceToServer:paymentMethodNonce.nonce];
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)dropInViewControllerDidCancel:(__unused BTDropInViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)postNonceToServer:(NSString *)paymentMethodNonce {
    
    double price = 1999.99;

    
    NSLog(@"%@",paymentMethodNonce);
    NSURL *paymentURL = [NSURL URLWithString:@"http://orcodevbox.co.uk/BTOrcun/iosPayment.php"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:paymentURL];
    
    request.HTTPBody = [[NSString stringWithFormat:@"amount=%ld&payment_method_nonce=%@", (long)price,paymentMethodNonce] dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPMethod = @"POST";
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSString *paymentResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        // TODO: Handle success and failure
        
        // Logging the HTTP request so we can see what is being sent to the server side
        NSLog(@"Request body %@", [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding]);
        
        // Trimming the response for success/failure check so it takes less time to determine the result
        NSString *trimResult =[paymentResult substringToIndex:50];
        
        // Log the transaction result
        NSLog(@"%@",paymentResult);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // Checking the result for the string "Successful" and updating GUI elements
            if ([trimResult containsString:@"Successful"]) {
                NSLog(@"Transaction is successful!");
                resultCheck = @"Transaction successful";

                
            } else {
                NSLog(@"Transaction failed! Contact Mat!");
                resultCheck = @"Transaction failed!Contact Mat!";

            }
            
            // Create an alert controller to display the transaction result
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:resultCheck
                                                                           message:paymentResult
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
            
            
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:
                                            UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                
                                                NSLog(@"You pressed button OK");
                                            }];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];
        });
    }] resume];
    

}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
