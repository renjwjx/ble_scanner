//
//  BLEBatteryServiceDemoViewController.m
//  BLE_Scanner
//
//  Created by Chip Keyes on 2/7/13.
//  Copyright (c) 2013 Chip Keyes. All rights reserved.
//

#import "BLEBatteryServiceDemoViewController.h"
#import "CBUUID+StringExtraction.h"
#include "ServiceAndCharacteristicMacros.h"


@interface BLEBatteryServiceDemoViewController ()

// Unsigned integer representation of battery level
@property (nonatomic)NSUInteger batteryLevel;

// UIProgressView used to display battery life percentage
@property (weak, nonatomic) IBOutlet UIProgressView *batteryMeter;

//Label which displays battery life percentage as an integer
@property (weak, nonatomic) IBOutlet UILabel *batteryLevelLabel;

// Label which displays peripheral status and activity.
@property (weak, nonatomic) IBOutlet UILabel *peripheralStatusLabel;

// Spinner activity indicator whihc is active when device is being accessed.
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *peripheralStatusSpinner;

@end

@implementation BLEBatteryServiceDemoViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}



/*
 *
 * Method Name:  <#name#>
 *
 * Description:  <#description#>
 *
 * Parameter(s): <#parameters#>
 *
 */
-(void)discoverServiceCharacteristics : (CBService *)service
{
    
    BOOL discoverIssued = [[self class]discoverServiceCharacteristics:service];
    if (discoverIssued)
    {
        
        self.peripheralStatusLabel.textColor = [UIColor greenColor];
        self.peripheralStatusLabel.text = @"Discovering service characteristics.";
        [self.peripheralStatusSpinner startAnimating];
        
    }
    else
    {
        DLog(@"Failed to discover characteristic, peripheral not connected.");
        [[self class]setPeripheral:service.peripheral ConnectionStatus:self.peripheralStatusLabel];
    }
    
}



/*
 *
 * Method Name:  <#name#>
 *
 * Description:  <#description#>
 *
 * Parameter(s): <#parameters#>
 *
 */
-(void)readCharacteristic: (NSString *)uuid forService:(CBService *)service
{
    BOOL readIssued = NO;
    
    readIssued = [[self class]readCharacteristic:uuid forService:service];
    if (readIssued)
    {
        self.peripheralStatusLabel.textColor = [UIColor greenColor];
        self.peripheralStatusLabel.text = @"Reading Characteristic.";
        [self.peripheralStatusSpinner startAnimating];
    }
}



/*
 *
 * Method Name:  viewDidLoad
 *
 * Description:  Complete setup of view controller.
 *
 * Parameter(s): None.
 *
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
	
    
    self.batteryService.peripheral.delegate = self;
    
    [[self class]setPeripheral:self.batteryService.peripheral ConnectionStatus:self.peripheralStatusLabel];
    
    // determine if BATTERY_LEVEL_CHARACTERISTIC has been discovered
    BOOL batteryFound = NO;
    for (CBCharacteristic * characteristic in self.batteryService.characteristics)
    {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BATTERY_LEVEL_CHARACTERISTIC ]])
        {
            batteryFound = YES;
        }
    }
    
    if ( batteryFound)
    {
        [self readCharacteristic:BATTERY_LEVEL_CHARACTERISTIC forService:self.batteryService];
    }
    else
    {
        // discover service characteristics
        [self discoverServiceCharacteristics:self.batteryService];
    }
    
}


- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CBPeripheralDelegate


/*
 *
 * Method Name:  peripheral:didUpdateValueForCharacteristic:error
 *
 * Description:  CBPeripheralDelegate method invoked when chracteristic is read or error occurs when reading characteristic.
 *
 * Parameter(s): See CBPeripheralDelegate documentation.
 *
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
    [self.peripheralStatusSpinner stopAnimating];
    [[self class]setPeripheral:self.batteryService.peripheral ConnectionStatus:self.peripheralStatusLabel];
    
    if (!error)
    {
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BATTERY_LEVEL_CHARACTERISTIC ]])
        {
            DLog(@"Characteristic value read updated.");
        
            char batteryValue;
            [characteristic.value getBytes:&batteryValue length:1];
        
            self.batteryLevel = (NSUInteger)batteryValue;
            DLog(@"Battery level read: %i",self.batteryLevel);
            self.batteryMeter.progress = (float)self.batteryLevel /100.0;
            self.batteryLevelLabel.text = [NSString  stringWithFormat: @"%i%%",self.batteryLevel];
        }
        
    }
    else
    {
        DLog(@"Error Updating Characteristic: %@",error.description);
    }
}


/*
 *
 * Method Name:  peripheral:didDiscoverCharacteristicsForService:error
 *
 * Description:  CBPeripheralDelegate method invoked when chracteristic is discovered or error occurs when reading characteristic.
 *
 * Parameter(s): See CBPeripheralDelegate documentation.
 *
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    DLog(@"didDiscoverCharacteristicsForService invoked");
    
    [self.peripheralStatusSpinner stopAnimating];
     [[self class]setPeripheral:self.batteryService.peripheral ConnectionStatus:self.peripheralStatusLabel];
    
    if (error == nil)
    {
        DLog(@"Reading battery level");
        [self readCharacteristic:BATTERY_LEVEL_CHARACTERISTIC forService:self.batteryService];
    }
    else
    {
        DLog(@"Error Updating Characteristic: %@",error.description);
    }
}


@end
