use clone::Clone;
use array::ArrayTrait;
use traits::Into;
use traits::TryInto;
use option::OptionTrait;
use starknet::{
    ContractAddress,
    Felt252TryIntoContractAddress
};
use zklink::utils::math::{
    felt252_fast_pow2,
    u128_fast_pow2,
    u128_div_rem,
    u128_join,
    u128_split,
    u128_sub_value,
    usize_div_rem
};
use zklink::utils::utils::{
    u128_array_slice,
    u8_array_to_u256
};
use zklink::utils::keccak::keccak_u128s_be;
use zklink::utils::sha256::sha256;

// Bytes is a dynamic array of u128, where each element contains 16 bytes.
const BYTES_PER_ELEMENT: usize = 16;

// Note that:   In Bytes, there are many variables about size and length.
//              We use size to represent the number of bytes in Bytes.
//              We use length to represent the number of elements in Bytes.

// Bytes is a cairo implementation of solidity Bytes in Big-endian.
// It is a dynamic array of u128, where each element contains 16 bytes.
// To save cost, the last element MUST be filled fully.
// That's means that every element should and MUST contains 16 bytes.
// For example, if we have a Bytes with 33 bytes, we will have 3 elements.
// Theroetically, the bytes looks like this:
//      first element:  [16 bytes]
//      second element: [16 bytes]
//      third element:  [1 byte]
// But in zkLink Bytes, the last element should be padded with zero to make
// it 16 bytes. So the zkLink bytes looks like this:
//      first element:  [16 bytes]
//      second element: [16 bytes]
//      third element:  [1 byte] + [15 bytes zero padding]

// Bytes is a dynamic array of u128, where each element contains 16 bytes.
//  - size: the number of bytes in the Bytes
//  - data: the data of the Bytes
#[derive(Drop, Clone, Serde)]
struct Bytes {
    size: usize,
    data: Array<u128>
}

// You can impl this trait for your own type.
// To make it able to read type T from Bytes.
// Call: ReadBytes::<T>::read(@bytes, offset);
trait ReadBytes<T> {
    fn read(bytes: @Bytes, offset: usize) -> (usize, T);
}

trait BytesTrait {
    // Create a Bytes from an array of u128
    fn new(size: usize, data: Array::<u128>) -> Bytes;
    // Create an empty Bytes
    fn new_empty() -> Bytes;
    // Locate offset in Bytes
    fn locate(offset: usize) -> (usize, usize);
    // Get Bytes size
    fn size(self: @Bytes) -> usize;
    // Read value with size bytes from Bytes, and packed into u128
    fn read_u128_packed(self: @Bytes, offset: usize, size: usize) -> (usize, u128);
    // Read value with element_size bytes from Bytes, and packed into u128 array
    fn read_u128_array_packed(self: @Bytes, offset: usize, array_length: usize, element_size: usize) -> (usize, Array<u128>);
    // Read value with size bytes from Bytes, and packed into felt252
    fn read_felt252_packed(self: @Bytes, offset: usize, size: usize) -> (usize, felt252);
    // Read a u8 from Bytes
    fn read_u8(self: @Bytes, offset: usize) -> (usize, u8);
    // Read a u16 from Bytes
    fn read_u16(self: @Bytes, offset: usize) -> (usize, u16);
    // Read a u32 from Bytes
    fn read_u32(self: @Bytes, offset: usize) -> (usize, u32);
    // Read a usize from Bytes
    fn read_usize(self: @Bytes, offset: usize) -> (usize, usize);
    // Read a u64 from Bytes
    fn read_u64(self: @Bytes, offset: usize) -> (usize, u64);
    // Read a u128 from Bytes
    fn read_u128(self: @Bytes, offset: usize) -> (usize, u128);
    // Read a u256 from Bytes
    fn read_u256(self: @Bytes, offset: usize) -> (usize, u256);
    // Read a u256 array from Bytes
    fn read_u256_array(self: @Bytes, offset: usize, array_length: usize) -> (usize, Array<u256>);
    // Read sub Bytes with size bytes from Bytes
    fn read_bytes(self: @Bytes, offset: usize, size: usize) -> (usize, Bytes);
    // Read a ContractAddress from Bytes
    fn read_address(self: @Bytes, offset: usize) -> (usize, ContractAddress);
    // Write value with size bytes into Bytes, value is packed into u128
    fn append_u128_packed(ref self: Bytes, value: u128, size: usize);
    // Write u8 into Bytes
    fn append_u8(ref self: Bytes, value: u8);
    // Write u16 into Bytes
    fn append_u16(ref self: Bytes, value: u16);
    // Write u32 into Bytes
    fn append_u32(ref self: Bytes, value: u32);
    // Write usize into Bytes
    fn append_usize(ref self: Bytes, value: usize);
    // Write u64 into Bytes
    fn append_u64(ref self: Bytes, value: u64);
    // Write u128 into Bytes
    fn append_u128(ref self: Bytes, value: u128);
    // Write u256 into Bytes
    fn append_u256(ref self: Bytes, value: u256);
    // Write address into Bytes
    fn append_address(ref self: Bytes, value: ContractAddress);
    // keccak hash
    fn keccak(self: @Bytes) -> u256;
    // sha256 hash
    fn sha256(self: @Bytes) -> u256;
}

impl BytesImpl of BytesTrait {
    fn new(size: usize, data: Array::<u128>) -> Bytes {
        Bytes {
            size,
            data
        }
    }

    fn new_empty() -> Bytes {
        let mut data = ArrayTrait::<u128>::new();
        data.append(0);
        Bytes {
            size: 0_usize,
            data: data
        }
    }

    // Locat offset in Bytes
    // Arguments:
    //  - offset: the offset in Bytes
    // Returns:
    //  - element_index: the index of the element in Bytes
    //  - element_offset: the offset in the element
    fn locate(offset: usize) -> (usize, usize) {
        usize_div_rem(offset, BYTES_PER_ELEMENT)
    }

    // Get Bytes size
    fn size(self: @Bytes) -> usize {
        *self.size
    }

    // Read value with size bytes from Bytes, and packed into u128
    // Arguments:
    //  - offset: the offset in Bytes
    //  - size: the number of bytes to read
    // Returns:
    //  - new_offset: next value offset in Bytes
    //  - value: the value packed into u128
    fn read_u128_packed(self: @Bytes, offset: usize, size: usize) -> (usize, u128) {
        // check
        assert(offset + size <= self.size(), 'out of bound');
        assert(size * 8 <= 128, 'too large');

        // check value in one element or two
        // if value in one element, just read it
        // if value in two elements, read them and join them
        let (element_index, element_offset) = BytesTrait::locate(offset);
        let value_in_one_element = element_offset + size <= BYTES_PER_ELEMENT;

        if value_in_one_element {
            let value = u128_sub_value(*self.data[element_index], BYTES_PER_ELEMENT, element_offset, size);
            return (offset + size, value);
        } else {
            let (_, end_element_offset) = BytesTrait::locate(offset + size);
            let left = u128_sub_value(*self.data[element_index], BYTES_PER_ELEMENT, element_offset, BYTES_PER_ELEMENT - element_offset);
            let right = u128_sub_value(*self.data[element_index + 1], BYTES_PER_ELEMENT, 0, end_element_offset);
            let value = u128_join(left, right, end_element_offset);
            return (offset + size, value);
        }
    }

    fn read_u128_array_packed(self: @Bytes, offset: usize, array_length: usize, element_size: usize) -> (usize, Array<u128>) {
        assert(offset + array_length * element_size <= self.size(), 'out of bound');
        let mut array = ArrayTrait::<u128>::new();

        if array_length == 0 {
            return (offset, array);
        }
        let mut offset = offset;
        let mut i = array_length;
        loop {
            let (new_offset, value) = self.read_u128_packed(offset, element_size);
            array.append(value);
            offset = new_offset;
            i -= 1;
            if i == 0 {
                break();
            };
        };
        (offset, array)
    }

    // Read value with size bytes from Bytes, and packed into felt252
    fn read_felt252_packed(self: @Bytes, offset: usize, size: usize) -> (usize, felt252) {
        // check
        assert(offset + size <= self.size(), 'out of bound');
        // Bytes unit is one byte
        // felt252 can hold 31 bytes max
        assert(size * 8 <= 248, 'too large');

        if size <= 16 {
            let (new_offset, value) = self.read_u128_packed(offset, size);
            return (new_offset, value.into());
        } else {
            let (new_offset, high) = self.read_u128_packed(offset, size - 16);
            let (new_offset, low) = self.read_u128_packed(new_offset, 16);
            return (new_offset, u256{low, high}.try_into().unwrap());
        }
    }

    // Read a u8 from Bytes
    fn read_u8(self: @Bytes, offset: usize) -> (usize, u8) {
        let (new_offset, value) = self.read_u128_packed(offset, 1);
        (new_offset, value.try_into().unwrap())
    }
    // Read a u16 from Bytes
    fn read_u16(self: @Bytes, offset: usize) -> (usize, u16) {
        let (new_offset, value) = self.read_u128_packed(offset, 2);
        (new_offset, value.try_into().unwrap())
    }
    // Read a u32 from Bytes
    fn read_u32(self: @Bytes, offset: usize) -> (usize, u32) {
        let (new_offset, value) = self.read_u128_packed(offset, 4);
        (new_offset, value.try_into().unwrap())
    }
    // Read a usize from Bytes
    fn read_usize(self: @Bytes, offset: usize) -> (usize, usize) {
        let (new_offset, value) = self.read_u128_packed(offset, 8);
        (new_offset, value.try_into().unwrap())
    }
    // Read a u64 from Bytes
    fn read_u64(self: @Bytes, offset: usize) -> (usize, u64) {
        let (new_offset, value) = self.read_u128_packed(offset, 8);
        (new_offset, value.try_into().unwrap())
    }

    fn read_u128(self: @Bytes, offset: usize) -> (usize, u128) {
        self.read_u128_packed(offset, 16)
    }

    // read a u256 from Bytes
    fn read_u256(self: @Bytes, offset: usize) -> (usize, u256) {
        // check
        assert(offset + 32 <= self.size(), 'out of bound');

        let (element_index, element_offset) = BytesTrait::locate(offset);
        let (new_offset, high) = self.read_u128(offset);
        let (new_offset, low) = self.read_u128(new_offset);

        (new_offset, u256 { low, high })
    }

    // read a u256 array from Bytes
    fn read_u256_array(self: @Bytes, offset: usize, array_length: usize) -> (usize, Array<u256>) {
        assert(offset + array_length * 32 <= self.size(), 'out of bound');
        let mut array = ArrayTrait::<u256>::new();
        
        if array_length == 0 {
            return (offset, array);
        }

        let mut offset = offset;
        let mut i = array_length;
        loop {
            let (new_offset, value) = self.read_u256(offset);
            array.append(value);
            offset = new_offset;
            i -= 1;
            if i == 0 {
                break();
            };
        };
        (offset, array)
    }

    // read sub Bytes from Bytes
    fn read_bytes(self: @Bytes, offset: usize, size: usize) -> (usize, Bytes) {
        // check
        assert(offset + size <= self.size(), 'out of bound');
        let mut array = ArrayTrait::<u128>::new();
        if size == 0 {
            return (offset, BytesTrait::new(0, array));
        }

        // read full array element for sub_bytes
        let mut offset = offset;
        let mut sub_bytes_full_array_len = size / BYTES_PER_ELEMENT;
        loop {
            let (new_offset, value) = self.read_u128(offset);
            array.append(value);
            offset = new_offset;
            sub_bytes_full_array_len -= 1;
            if sub_bytes_full_array_len == 0 {
                break();
            };
        };

        // process last array element for sub_bytes
        // 1. read last element real value;
        // 2. make last element full with padding 0;
        let sub_bytes_last_element_size = size % BYTES_PER_ELEMENT;
        if sub_bytes_last_element_size > 0 {
            let (new_offset, value) = self.read_u128_packed(offset, sub_bytes_last_element_size);
            let padding = BYTES_PER_ELEMENT - sub_bytes_last_element_size;
            let value = u128_join(value, 0, padding);
            array.append(value);
            offset = new_offset;
        }

        return (offset, BytesTrait::new(size, array));
    }

    // read address from Bytes
    fn read_address(self: @Bytes, offset: usize) -> (usize, ContractAddress) {
        let (new_offset, value) = self.read_u256(offset);
        let address: felt252 = value.try_into().unwrap();
        (new_offset, address.try_into().unwrap())
    }

    // Write value with size bytes into Bytes, value is packed into u128
    fn append_u128_packed(ref self: Bytes, value: u128, size: usize) {
        assert(size <= 16, 'size must be less than 16');

        let Bytes {size: old_bytes_size, mut data} = self;

        let (last_data_index, last_element_size) = BytesTrait::locate(old_bytes_size);
        let (last_element_value, _) = u128_split(*data[last_data_index], 16, last_element_size);
        data = u128_array_slice(@data, 0, last_data_index);

        if last_element_size == 0 {
            let padded_value = u128_join(value, 0, BYTES_PER_ELEMENT - size);
            data.append(padded_value);
        } else {
            if size + last_element_size > BYTES_PER_ELEMENT {
                let (left, right) = u128_split(value, size, BYTES_PER_ELEMENT - last_element_size);
                let value_full = u128_join(last_element_value, left, BYTES_PER_ELEMENT - last_element_size);
                let value_padded = u128_join(right, 0, 2 * BYTES_PER_ELEMENT - size - last_element_size);
                data.append(value_full);
                data.append(value_padded);
            } else {
                let value = u128_join(last_element_value, value, size);
                let value_padded = u128_join(value, 0, BYTES_PER_ELEMENT - size - last_element_size);
                data.append(value_padded);
            }
        }
        self = Bytes { size: old_bytes_size + size, data }
    }

    // Write u8 into Bytes
    fn append_u8(ref self: Bytes, value: u8) {
        self.append_u128_packed(value.into(), 1)
    }
    // Write u16 into Bytes
    fn append_u16(ref self: Bytes, value: u16) {
        self.append_u128_packed(value.into(), 2)
    }
    // Write u32 into Bytes
    fn append_u32(ref self: Bytes, value: u32) {
        self.append_u128_packed(value.into(), 4)
    }
    // Write usize into Bytes
    fn append_usize(ref self: Bytes, value: usize) {
        self.append_u128_packed(value.into(), 4)
    }
    // Write u64 into Bytes
    fn append_u64(ref self: Bytes, value: u64) {
        self.append_u128_packed(value.into(), 8)
    }
    // Write u128 into Bytes
    fn append_u128(ref self: Bytes, value: u128) {
        self.append_u128_packed(value, 16)
    }
    // Write u256 into Bytes
    fn append_u256(ref self: Bytes, value: u256) {
        self.append_u128(value.high);
        self.append_u128(value.low);
    }
    // Write address into Bytes
    fn append_address(ref self: Bytes, value: ContractAddress) {
        let address_felt256: felt252 = value.into();
        let address_u256: u256 = address_felt256.into();
        self.append_u256(address_u256)
    }

    // keccak hash
    fn keccak(self: @Bytes) -> u256 {
        let (last_data_index, last_element_size) = BytesTrait::locate(self.size());
        // To cumpute hash, we should remove 0 padded
        let (last_element_value, _) = u128_split(*self.data[last_data_index], 16, last_element_size);
        let mut hash_data = u128_array_slice(self.data, 0, last_data_index);
        hash_data.append(last_element_value);
        keccak_u128s_be(hash_data.span())
    }

    // sha256 hash
    fn sha256(self: @Bytes) -> u256 {
        let mut hash_data: Array<u8> = ArrayTrait::new();
        let mut i: usize = 0;
        let mut offset: usize = 0;
        loop {
            if i == self.size() {
                break();
            }
            let (new_offset, hash_data_item) = self.read_u8(offset);
            hash_data.append(hash_data_item);
            offset = new_offset;
            i += 1;
        };
        
        let output: Array<u8> = sha256(hash_data);
        u8_array_to_u256(output.span())
    }
}