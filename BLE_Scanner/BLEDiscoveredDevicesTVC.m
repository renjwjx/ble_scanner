//
//  BLEDiscoveredDevicesTVC.m
//  BLE_Scanner
//
//  Created by Chip Keyes on 1/29/13.
//  Copyright (c) 2013 Chip Keyes. All rights reserved.
//

#import "BLEDiscoveredDevicesTVC.h"
#import "CBUUID+StringExtraction.h"
#import "BLEConnectButtonCell.h"


// A label embedded in the data which displays ADVERTISING DATA in the table
#define ADVERTISEMENT_ROW 3

@interface BLEDiscoveredDevicesTVC ()

// The model for this table view controller
@property (nonatomic, strong) NSMutableArray *sections;

@property (nonatomic, strong)NSMutableArray *deviceRecords;

// controls NSLogging
@property (nonatomic) BOOL debug;


- (IBAction)connectButton:(UIButton *)sender;



@end

@implementation BLEDiscoveredDevicesTVC

@synthesize sections = _sections;
@synthesize deviceRecords = _deviceRecords;


-(NSMutableArray *)deviceRecords
{
    if (_deviceRecords == nil)
    {
        _deviceRecords = [NSMutableArray array];
    }
    
    return _deviceRecords;
}

// DiscoveredDevicesTVC model.
// 
//
// Sections is the data structure for the table where each section corresponds to a discovered peripheral. The array has two elements:
//     index 0 - an array which has an element for each discovered peripheral.
//             - each element array holds the lables which will be shown in a row cell belonging to the section's peripheral
//     index 1 - an aray which has an element for each discovered peripheral.
//             - each element array holds the data which corresponds to the label in index 0
// The number of sections (i.e. the number of discovered peripherals) can be found by looking
// at the count of either of the arrays at index 0 or index 1.
//
// The counts of the element arrays varies by the information the discovered device provides.
-(NSMutableArray*) sections
{
    if (_sections == nil)
    {
        // first array holds labels, 2nd array holds data
        _sections = [NSMutableArray arrayWithObjects:
                     [NSMutableArray array],
                     [NSMutableArray array], nil];
    }
    
    return _sections;
}

- (IBAction)connectButton:(UIButton*)sender
{
    UITableViewCell *owningCell;
    NSIndexPath *indexPath;
    BLEDiscoveryRecord * record;
    
    if (self.debug) NSLog(@"Connect Button pressed.");
    
    // the sender is the button
    // sender super view is the content view of the cell
    // sender super super is the table cell
    if ( [[[sender superview]superview] isKindOfClass:[UITableViewCell class]])
    {
        owningCell = (UITableViewCell*)[[sender superview]superview];
        
        // retrieve the indexPath
        indexPath = [self.tableView indexPathForCell:owningCell];
        if (self.debug) NSLog(@"Section index:  %i",indexPath.section);
        // get the device record
        record = [self.deviceRecords objectAtIndex:indexPath.section];
    
    
        // retrieve the current title of the button
        NSString *buttonTitle = sender.currentTitle;
        if ( [buttonTitle localizedCompare:@"Connect"]== NSOrderedSame)
        {
            // Ask the CBCentralManager to connect to the device 
            [self.delegate connectPeripheral:record.peripheral sender:owningCell];
            
            // At this point only the connection request has been made, we don't know if the connection was successful. Stay in the same view until the result of the connection request is known.
            
        }
        else if ([buttonTitle localizedCompare:@"Disconnect"] == NSOrderedSame)
        {
            NSLog(@"Button pressed with Disconnect title");
        }
               
    }
        
}


//Invoked when a BLE peripheral is discovered
-(void)deviceDiscovered: (BLEDiscoveryRecord *)deviceRecord
{
    // these arrays will be added to section 
    NSMutableArray *deviceInfo = [NSMutableArray array];
    NSMutableArray *cellLabel = [NSMutableArray array];
    
    // add the deviceRecord to the list of discovered devices
    [self.deviceRecords addObject:deviceRecord];
    
    // add the device name - index 0
    if (deviceRecord.peripheral.name == nil)
    {
        [deviceInfo addObject:@""];
    }
    else
    {
        [deviceInfo addObject:deviceRecord.peripheral.name];
    }
    [cellLabel addObject:@"Name"];
    
    // add the UUID - index 1
    CFUUIDRef uuid = deviceRecord.peripheral.UUID;
    CFStringRef s = CFUUIDCreateString(NULL, uuid);
    NSString *uuid_string = CFBridgingRelease(s);
    [deviceInfo addObject:uuid_string];
    [cellLabel addObject:@"UUID"];
    
    // add RSSI - index 2
    NSString *rssiString = [[NSString alloc]initWithFormat:@"%i",[deviceRecord.rssi shortValue]];
    [deviceInfo addObject:rssiString];
    [cellLabel addObject:@"RSSI"];
    
    // add placeholder for Advertisement Label
    [deviceInfo addObject:@""];
    [cellLabel addObject:@"ADVERTISEMENT"];
    
    // process advertisement data
    NSEnumerator *enumerator = [deviceRecord.advertisementData keyEnumerator];
    id key;
    while ((key = [enumerator nextObject]))
    {
        if ([key isKindOfClass:[NSString class]])
        {
            NSLog(@"Advertising key: %@",key);
            id value = [deviceRecord.advertisementData objectForKey:key];
            if ([value isKindOfClass:[NSString class]])
            {
                [deviceInfo addObject:value];
                [cellLabel addObject:key];
            }
            else if ([value isKindOfClass:[NSArray class]])
            {
                NSArray *valueData = (NSArray *)value;
                for (id item in valueData)
                {
                    if ([item isKindOfClass:[CBUUID class]])
                    {
                       
                        [deviceInfo addObject:[item representativeString]];
                        [cellLabel addObject:key];
                    }
                }
            }
            else  
            {
                // do nothing for now
            }
        }
    }


    // finally add placeholder for the connect button
    [deviceInfo addObject:@""];
    [cellLabel addObject:@""];
    
    // add peripheral item data to section array
    [[self.sections objectAtIndex:0] addObject:cellLabel];
    [[self.sections objectAtIndex:1] addObject:deviceInfo];
    
    [self.tableView reloadData];
    
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    _debug = YES;
    
}



- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//Toggle the connect button label corresponding to a discovered device which has either been connected or disconnected by the user.
-(void)toggleConnectButtonLabel : (CBPeripheral *)peripheral;
{
    // find all of the rows which have a peripheral matching the parameter using UUID as the key
    // for each corresponding device toggle the button so that connect -> disconnect or disconnect -> connect
    
    BOOL (^test)(id obj, NSUInteger idx, BOOL *stop);
    CFUUIDRef target = peripheral.UUID;
    test = ^(id obj, NSUInteger idx, BOOL *stop)
    {
        BLEDiscoveryRecord *record = (BLEDiscoveryRecord *)obj;
        CFUUIDRef uuid = record.peripheral.UUID;
        
        if ( CFEqual(target, uuid))
        {
            return YES;
        }
        return NO;
    };
    
    NSIndexSet *indexes = [self.deviceRecords indexesOfObjectsPassingTest:test];
    NSLog(@"indexes: %@", indexes);
    
    // swap the button lablels
    NSUInteger sectionIndex=[indexes firstIndex];
  
    NSString *currentTitle;
    while(sectionIndex != NSNotFound)
    {
        // the index represents the section number which corresponds to the peripheral
        NSArray *data = [[self.sections objectAtIndex:1] objectAtIndex:sectionIndex];
        NSUInteger lastItemIndex = [data count]-1;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:lastItemIndex inSection:sectionIndex];
        
        NSLog(@"row = %i",indexPath.row);
        
        
        BLEConnectButtonCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Connect" forIndexPath:indexPath];
       
        
        currentTitle = cell.connectDisconnectButton.currentTitle;
        if ( [currentTitle localizedCompare:@"Connect"] == NSOrderedSame)
        {
            [BLEConnectButtonCell setButtonTitle:(@"Disconnect") AtIndex:indexPath];
            
        }
        else
        {
            [BLEConnectButtonCell setButtonTitle:(@"Connect") AtIndex:indexPath];
            
        }
        
        sectionIndex=[indexes indexGreaterThanIndex: sectionIndex];
    }
        
    [self.tableView reloadData];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // this gets the array of labels, each element in this array corresponds to a device
    NSUInteger numberSections = [[self.sections objectAtIndex:0] count];
    NSLog(@"Number of sections, i.e discovered devices, in discovered device table: %i",numberSections);
    // Return the number of sections.
    return numberSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    // access the array which had labels for each peripheral;
    NSArray *deviceItems = [self.sections objectAtIndex:0];
    
    NSUInteger numRowsSection = [[deviceItems objectAtIndex:section] count];
    
    NSLog(@"Setting row count in discovered device table %d",numRowsSection);
    return numRowsSection;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    static NSString *CellIdentifier = @"DeviceContent";
    static NSString *AdvertisementCellIdentifier = @"Advertisement";
    static NSString *ConnectCellIdentifier = @"Connect";
    
    
    // get the label and data array which correspond to the section
    NSArray *labels = [[self.sections objectAtIndex:0] objectAtIndex:indexPath.section];
    
    NSArray *data = [[self.sections objectAtIndex:1] objectAtIndex:indexPath.section];
    if (indexPath.row == ADVERTISEMENT_ROW)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:AdvertisementCellIdentifier forIndexPath:indexPath];
        
    }
    else if (indexPath.row == ([data count]-1))
    {
        BLEConnectButtonCell *buttonCell = [tableView dequeueReusableCellWithIdentifier:ConnectCellIdentifier forIndexPath:indexPath];
        
        NSString *title = [BLEConnectButtonCell getButtonTitle:indexPath];
        [buttonCell.connectDisconnectButton setTitle:title forState:UIControlStateNormal];
        [buttonCell.connectDisconnectButton setTitle:title forState:UIControlStateHighlighted];
        
        cell = buttonCell;
        
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        cell.detailTextLabel.text = [data objectAtIndex:indexPath.row];
        cell.textLabel.text = [labels objectAtIndex:indexPath.row];
        
    }
    
    return cell;
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Did Select Row invoked");
    
}

@end
