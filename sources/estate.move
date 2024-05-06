module estate::estate {/home/bryan/devs/realestate-sui-move
    //imports
    use sui::transfer;
     use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::clock::{Self, Clock};
    use sui::object::{Self, UID, ID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};
    use std::option::{Option, none, some, is_some, contains, borrow};

    //errors
   const NotPropertyOwner: u64 = 1;
    const NotAgent: u64 = 2;
    const NotClient: u64 = 3;
    const EstateNotForSale: u64 = 4;
    const InsufficientBalance: u64 = 5;



    struct Property has key, store {
        owners: UID,
        name: String,
        description: String,
        address: String,
        type: u64,
        rentalStatus: bool,
      rentalRates: u64,
        salePrice: u64,
        area: u64,
        images: Vec<String>,
        videos: Vec<String>,
        documents: Vec<String>,
      tokenizationStatus: bool,
        status: u64,
    }

    //ownership record
    struct OwnershipRecord has key, store {
        propertyId: UID,
        ownerId: UID,
        ownershipStatus: u64,
        tokensAmount: u64,
    }

    //tokenization record
    struct TokenizationRecord has key, store {
        propertyId: UID,
        tokenId: UID,
        tokensAmount: u64,
        owners: vector<u8>,

    }

    //client record
    struct ClientRecord has key, store {
        clientId: UID,
        clientName: String,
        clientAddress: String,
        clientEmail: String,
        clientPhone: String,
        clientType: u64,
    }


    //create property
    public entry fun create_property(owner: UID, name: String, description: String, address: String, type: u64, rentalStatus: bool rentalRates: u64, salePrice: u64, area: u64, images: Vec<String>, videos: Vec<String>, documents: Vec<String>, status: u64, clock: &Clock, ctx: &mut TxContext) {
        let property_id = object::new(ctx);
        transfer::share_object(Property {
            owner: owner,
            name: name,
            description: description,
            address: address,
            type: type,
            rentalStatus: rentalStatus,
            rentalRates: rentalRates,
            salePrice: salePrice,
            area: area,
            images: images,
            videos: videos,
            documents: documents,
            tokenizationStatus: 0,
            status: status,
        });
    }
   

   //owners tokenize property
    public entry fun tokenize_property(owner: UID, propertyId: UID, tokensAmount: u64, owners: vector<u8>, clock: &Clock, ctx: &mut TxContext) {
        let property = object::get::<Property>(propertyId, ctx);
        if property.owner != owner {
            ctx.emit_error(NotPropertyOwner);
            return;
        }
        let tokenizationRecordId = object::new(ctx);
        transfer::share_object(TokenizationRecord {
            propertyId: propertyId,
            tokenId: tokenizationRecordId,
            tokensAmount: tokensAmount,
            owners: owners,
        });
    }


    //owners transfer property
    public entry fun transfer_property(owner: UID, propertyId: UID, newOwner: UID, clock: &Clock, ctx: &mut TxContext) {
        let property = object::get::<Property>(propertyId, ctx);
        if property.owner != owner {
            ctx.emit_error(NotPropertyOwner);
            return;
        }
        transfer::update_object::<Property>(propertyId, |property| {
            property.owner = newOwner;
        });
    }

    //owners transfer token
    public entry fun transfer_token(owner: UID, tokenId: UID, newOwner: UID, clock: &Clock, ctx: &mut TxContext) {
        let tokenizationRecord = object::get::<TokenizationRecord>(tokenId, ctx);
        if tokenizationRecord.owners[0] != owner {
            ctx.emit_error(NotPropertyOwner);
            return;
        }
        transfer::update_object::<TokenizationRecord>(tokenId, |tokenizationRecord| {
            tokenizationRecord.owners[0] = newOwner;
        });
    }


    //owners put property up for renting
    public entry fun put_property_up_for_rent(owner: UID, propertyId: UID, rentalRates: u64, clock: &Clock, ctx: &mut TxContext) {
        let property = object::get::<Property>(propertyId, ctx);
        if property.owner != owner {
            ctx.emit_error(NotPropertyOwner);
            return;
        }
        transfer::update_object::<Property>(propertyId, |property| {
            property.rentalRates = rentalRates;
        });
    }

//owners remove property from rental
    public entry fun remove_property_from_rental(owner: UID, propertyId: UID, clock
: &Clock, ctx: &mut TxContext) {
        let property = object::get::<Property>(propertyId, ctx);
        if property.owner != owner {
            ctx.emit_error(NotPropertyOwner);
            return;
        }
        transfer::update_object::<Property>(propertyId, |property| {
            property.rentalRates = 0;
        });
    }

    



        //client rents property
    public entry fun rent_property(clientId: UID, propertyId: UID, clock: &Clock, ctx: &mut TxContext) {
        let property = object::get::<Property>(propertyId, ctx);
        if property.status != 1 {
            ctx.emit_error(EstateNotForSale);
            return;
        }
        let balance = balance::get_balance(clientId, ctx);
        if balance < property.rentalRates {
            ctx.emit_error(InsufficientBalance);
            return;
        }
        transfer::update_object::<Property>(propertyId, |property| {
            property.owner = clientId;
        });
        transfer::transfer(clientId, property.rentalRates, ctx);

        //update property rental status
        transfer::update_object::<Property>(propertyId, |property| {
            property.rentalStatus = 1;
        });

        //update property status
        transfer::update_object::<Property>(propertyId, |property| {
            property.status = 0;
        });
    }


    //client unrents property
    public entry fun unrent_property(clientId: UID, propertyId: UID, clock: &Clock, ctx: &mut TxContext) {
        let property = object::get::<Property>(propertyId, ctx);
        if property.status != 1 {
            ctx.emit_error(EstateNotForSale);
            return;
        }
        let balance = balance::get_balance(clientId, ctx);
        if balance < property.rentalRates {
            ctx.emit_error(InsufficientBalance);
            return;
        }
        transfer::update_object::<Property>(propertyId, |property| {
            property.owner = clientId;
        });
        transfer::transfer(clientId, property.rentalRates, ctx);

        //update property rental status
        transfer::update_object::<Property>(propertyId, |property| {
            property.rentalStatus = 0;
        });

        //update property status
        transfer::update_object::<Property>(propertyId, |property| {
            property.status = 0;
        });
    }


    //client buys property
    public entry fun buy_property(clientId: UID, propertyId: UID, clock: &Clock, ctx: &mut TxContext) {
        let property = object::get::<Property>(propertyId, ctx);
        if property.status != 1 {
            ctx.emit_error(EstateNotForSale);
            return;
        }
        let balance = balance::get_balance(clientId, ctx);
        if balance < property.salePrice {
            ctx.emit_error(InsufficientBalance);
            return;
        }
        transfer::update_object::<Property>(propertyId, |property| {
            property.owner = clientId;
        });
        transfer::transfer(clientId, property.salePrice, ctx);

        //update property status
        transfer::update_object::<Property>(propertyId, |property| {
            property.status = 0;
        });
    }


    //client updates profile
    public entry fun update_client_profile(clientId: UID, clientName: String, clientAddress: String, clientEmail: String, clientPhone: String, clientType: u64, clock: &Clock, ctx: &mut TxContext) {
        let clientRecord = object::get::<ClientRecord>(clientId, ctx);
        if clientRecord.clientId != clientId {
            ctx.emit_error(NotClient);
            return;
        }
        transfer::update_object::<ClientRecord>(clientId, |clientRecord| {
            clientRecord.clientName = clientName;
            clientRecord.clientAddress = clientAddress;
            clientRecord.clientEmail = clientEmail;
            clientRecord.clientPhone = clientPhone;
            clientRecord.clientType = clientType;
        });
    }

   


    
    



}
