#![no_std]

use embedded_hal::{
    delay::DelayUs,
    digital::{InputPin, OutputPin},
};
use one_wire_bus::{Address, OneWire, OneWireError};

pub const FAMILY_CODE: u8 = 0x42;

pub const CMD_CHAIN: u8 = 0x99;
pub const CMD_COND_READ_ROM: u8 = 0x0F;
pub const CMD_PIO_READ: u8 = 0xF5;
pub const CMD_PIO_WRITE: u8 = 0xA5;

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

    pub fn pio_write<T, E>(
        &self,
        onewire: &mut OneWire<T>,
        delay: &mut impl DelayUs,
        pioa: embedded_hal::digital::PinState,
        piob: embedded_hal::digital::PinState,
    ) -> Result<(), OneWireError<E>>
    where
        T: InputPin<Error = E>,
        T: OutputPin<Error = E>,
    {
        let value = 0b1111_1100 | (bool::from(piob) as u8) << 1 | bool::from(pioa) as u8;
        onewire.send_command(CMD_PIO_WRITE, Some(&self.address), delay)?;
        onewire.write_bytes(&[value, !value], delay)?;
        onewire.read_byte(delay)?;
        Ok(())
    }
}

pub fn sequence_detect<'a, T, E, D: DelayUs>(
    bus: &'a mut OneWire<T>,
    delay: &'a mut D,
) -> Result<SequenceDetect<'a, T, E, D>, OneWireError<E>>
where
    T: InputPin<Error = E>,
    T: OutputPin<Error = E>,
{
    SequenceDetect::new(bus, delay)
}

pub struct SequenceDetect<'a, T: InputPin<Error = E> + OutputPin<Error = E>, E, D: DelayUs> {
    bus: &'a mut OneWire<T>,
    delay: &'a mut D,
}

impl<'a, T: InputPin<Error = E> + OutputPin<Error = E>, E, D: DelayUs> SequenceDetect<'a, T, E, D> {
    fn new(bus: &'a mut OneWire<T>, delay: &'a mut D) -> Result<Self, OneWireError<E>> {
        // Skip rom, chain off
        bus.send_command(CMD_CHAIN, None, delay)?;
        bus.write_bytes(&[CHAIN_OFF, !CHAIN_OFF], delay)?;

        // Skip rom, chain on
        bus.send_command(CMD_CHAIN, None, delay)?;
        bus.write_bytes(&[CHAIN_ON, !CHAIN_ON], delay)?;
        let rx_value = bus.read_byte(delay)?;
        assert_eq!(rx_value, 0xAA);
        Ok(Self { bus, delay })
    }

    fn try_next(&mut self) -> Result<Option<Address>, OneWireError<E>> {
        // Conditional read rom, [receive rom]
        self.bus.reset(self.delay)?;
        self.bus.write_byte(CMD_COND_READ_ROM, self.delay)?;
        let mut address_bytes = [0; 8];
        self.bus.read_bytes(&mut address_bytes, self.delay)?;
        let address = Address(u64::from_le_bytes(address_bytes));

        if address == Address(u64::MAX) {
            // No more device in chain
            return Ok(None);
        }

        one_wire_bus::crc::check_crc8(&address_bytes)?;

        // Chain done
        self.bus
            .send_command(CMD_CHAIN, Some(&address), self.delay)?;
        self.bus
            .write_bytes(&[CHAIN_DONE, !CHAIN_DONE], self.delay)?;

        Ok(Some(address))
    }
}

impl<T: InputPin<Error = E> + OutputPin<Error = E>, E, D: DelayUs> Iterator
    for SequenceDetect<'_, T, E, D>
{
    type Item = Result<Address, OneWireError<E>>;

    fn next(&mut self) -> Option<Result<Address, OneWireError<E>>> {
        match self.try_next() {
            Ok(Some(addr)) => Some(Ok(addr)),
            Ok(None) => {
                // No more devices in the sequence
                None
            }
            Err(e) => Some(Err(e)),
        }
    }
}

impl<T: InputPin<Error = E> + OutputPin<Error = E>, E, D: DelayUs> Drop
    for SequenceDetect<'_, T, E, D>
{
    fn drop(&mut self) {
        // Skip rom, chain off
        let _ = self.bus.send_command(CMD_CHAIN, None, self.delay);
        let _ = self.bus.write_bytes(&[CHAIN_OFF, !CHAIN_OFF], self.delay);
    }
}
