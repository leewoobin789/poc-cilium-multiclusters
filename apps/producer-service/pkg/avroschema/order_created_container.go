// Code generated by github.com/actgardner/gogen-avro/v10. DO NOT EDIT.
/*
 * SOURCE:
 *     value-schema.avsc
 */
package avroschema

import (
	"io"

	"github.com/actgardner/gogen-avro/v10/compiler"
	"github.com/actgardner/gogen-avro/v10/container"
	"github.com/actgardner/gogen-avro/v10/vm"
)

func NewOrderCreatedWriter(writer io.Writer, codec container.Codec, recordsPerBlock int64) (*container.Writer, error) {
	str := NewOrderCreated()
	return container.NewWriter(writer, codec, recordsPerBlock, str.Schema())
}

// container reader
type OrderCreatedReader struct {
	r io.Reader
	p *vm.Program
}

func NewOrderCreatedReader(r io.Reader) (*OrderCreatedReader, error) {
	containerReader, err := container.NewReader(r)
	if err != nil {
		return nil, err
	}

	t := NewOrderCreated()
	deser, err := compiler.CompileSchemaBytes([]byte(containerReader.AvroContainerSchema()), []byte(t.Schema()))
	if err != nil {
		return nil, err
	}

	return &OrderCreatedReader{
		r: containerReader,
		p: deser,
	}, nil
}

func (r OrderCreatedReader) Read() (OrderCreated, error) {
	t := NewOrderCreated()
	err := vm.Eval(r.r, r.p, &t)
	return t, err
}