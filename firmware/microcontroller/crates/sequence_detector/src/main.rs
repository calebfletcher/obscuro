#![no_std]
#![no_main]
#![feature(type_alias_impl_trait)]

use core::fmt::Debug;
use defmt::info;
use ds28ea00::Ds28ea00;
use embassy_executor::Spawner;
use embassy_stm32::gpio::{Level, Pull, Speed};
use embassy_stm32::time::Hertz;
use embassy_stm32::Config;
use embassy_time::{Duration, Timer};
use embedded_hal::delay::DelayUs;
use embedded_hal::digital::{InputPin, OutputPin};
use one_wire_bus::OneWire;
use {defmt_rtt as _, panic_probe as _};

#[embassy_executor::main]
async fn main(_spawner: Spawner) {
    info!("Starting sequence detector");

    // Init clocks
    let mut config = Config::default();
    config.rcc.hse = Some(Hertz(8_000_000));
    config.rcc.sys_ck = Some(Hertz(64_000_000));
    config.rcc.pclk1 = Some(Hertz(32_000_000));
    let p = embassy_stm32::init(config);

    let mut delay = embassy_time::Delay;

    // Initialise one-wire bus
    let one_wire_pin: embassy_stm32::gpio::OutputOpenDrain<'_, embassy_stm32::peripherals::PA12> =
        embassy_stm32::gpio::OutputOpenDrain::new(p.PA12, Level::High, Speed::VeryHigh, Pull::None);
    let mut one_wire_bus = OneWire::new(one_wire_pin).unwrap();

    //find_onewire_devices(&mut one_wire_bus, &mut delay);

    // Start sequence detect
    let mut devices: [_; 8] = core::array::from_fn(|_| None);
    for (i, addr) in ds28ea00::sequence_detect(&mut one_wire_bus, &mut delay)
        .unwrap()
        .enumerate()
    {
        let addr = addr.unwrap();
        info!("sequence: address {:#x}", addr.0);
        devices[i] = Some(Ds28ea00::new::<core::convert::Infallible>(addr).unwrap());
    }
    info!("finished bus enumeration");

    loop {
        Timer::after(Duration::from_secs(1)).await;
    }
}

fn find_onewire_devices<P, E>(bus: &mut OneWire<P>, delay: &mut impl DelayUs)
where
    P: OutputPin<Error = E> + InputPin<Error = E>,
    E: Debug,
{
    for device_address in bus.devices(false, delay) {
        let device_address = device_address.unwrap();
        info!(
            "Found device at address {:#x} with family code: {:#x}",
            device_address.0,
            device_address.family_code()
        );
    }
}
