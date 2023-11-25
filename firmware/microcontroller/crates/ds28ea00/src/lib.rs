#![no_std]

use defmt::info;
use embedded_hal::{
    delay::DelayUs,
    digital::{InputPin, OutputPin},
};
use one_wire_bus::{Address, OneWire, OneWireError};

pub const FAMILY_CODE: u8 = 0x42;

pub const CMD_CHAIN: u8 = 0x99;
pub const CMD_COND_READ_ROM: u8 = 0x0F;

pub const CHAIN_OFF: u8 = 0x3C;
pub const CHAIN_ON: u8 = 0x5A;
pub const CHAIN_DONE: u8 = 0x96;

pub struct Ds28ea00 {
    address: Address,
}

impl Ds28ea00 {
    pub fn new<E>(address: Address) -> Result<Self, OneWireError<E>> {
        if address.family_code() == FAMILY_CODE {
            Ok(Ds28ea00 { address })
        } else {
            Err(OneWireError::FamilyCodeMismatch)
        }
    }

    pub fn address(&self) -> &Address {
        &self.address
    }

    // pub fn start_temp_measurement<T, E>(
    //     &self,
    //     onewire: &mut OneWire<T>,
    //     delay: &mut impl DelayUs,
    // ) -> Result<(), OneWireError<E>>
    // where
    //     T: InputPin<Error = E>,
    //     T: OutputPin<Error = E>,
    // {
    //     onewire.send_command(
    //         one_wire_bus::commands::SEARCH_ALARM,
    //         Some(&self.address),
    //         delay,
    //     )?;
    //     Ok(())
    // }
}

pub fn sequence_detect<T, E>(
    bus: &mut OneWire<T>,
    delay: &mut impl DelayUs,
) -> Result<(), OneWireError<E>>
where
    T: InputPin<Error = E>,
    T: OutputPin<Error = E>,
{
    // Skip rom, chain off
    bus.send_command(CMD_CHAIN, None, delay)?;
    bus.write_bytes(&[CHAIN_OFF, !CHAIN_OFF], delay)?;

    // Skip rom, chain on
    bus.send_command(CMD_CHAIN, None, delay)?;
    bus.write_bytes(&[CHAIN_ON, !CHAIN_ON], delay)?;
    let rx_value = bus.read_byte(delay)?;
    assert_eq!(rx_value, 0xAA);

    loop {
        // Conditional read rom, [receive rom]
        bus.reset(delay)?;
        bus.write_byte(CMD_COND_READ_ROM, delay)?;
        let mut address_bytes = [0; 8];
        bus.read_bytes(&mut address_bytes, delay)?;
        let address = Address(u64::from_le_bytes(address_bytes));

        if address == Address(u64::MAX) {
            // No more device in chain
            break;
        }

        one_wire_bus::crc::check_crc8(&address_bytes)?;
        info!("sequence: address {:#x}", address.0);

        // Chain done
        bus.send_command(CMD_CHAIN, Some(&address), delay)?;
        bus.write_bytes(&[CHAIN_DONE, !CHAIN_DONE], delay)?;
    }

    // Skip rom, chain off
    bus.send_command(CMD_CHAIN, None, delay)?;
    bus.write_bytes(&[CHAIN_OFF, !CHAIN_OFF], delay)?;

    Ok(())
}
